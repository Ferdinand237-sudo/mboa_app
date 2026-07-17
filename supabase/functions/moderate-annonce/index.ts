// Edge Function déclenchée par le trigger public.moderer_nouvelle_annonce()
// (net.http_post, AFTER INSERT sur logements et articles — même mécanisme
// que public.notifier_nouvelle_annonce()). Analyse chaque nouvelle annonce :
//   1. hash perceptuel (dHash 64 bits, via imagescript) de chaque photo,
//      comparé aux hash déjà connus d'autres vendeurs pour détecter la
//      réutilisation frauduleuse d'images (distance de Hamming <= 10).
//   2. classification de contenu via l'API Gemini (texte + images) :
//      pornographie, violence, stupéfiants, arnaque suspectée. JAMAIS basé
//      sur la cohérence des prix (trop variable d'un quartier à l'autre).
//   3. combinaison en un risk_score (0-100) et une décision (publie /
//      a_verifier / bloque).
// En cas d'échec, de timeout, ou d'absence de GEMINI_API_KEY : décision
// a_verifier au minimum (jamais de publication aveugle, jamais de blocage
// silencieux sans trace dans moderation_ia).

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { encodeBase64 } from "https://deno.land/std@0.224.0/encoding/base64.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { Image } from "https://deno.land/x/imagescript@1.2.17/mod.ts";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.0-flash";
const GEMINI_TIMEOUT_MS = 15000;
const HAMMING_SEUIL = 10;
const MAX_IMAGES_GEMINI = 5;
const MAX_HASHES_COMPARES = 2000;

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

type AnnonceType = "logement" | "article";

interface Categories {
  pornographie: boolean;
  violence: boolean;
  stupefiants: boolean;
  arnaque_suspectee: boolean;
}

// ── Hash perceptuel (dHash 64 bits) ─────────────────────────────────
// Choix pragmatique face au pHash classique (DCT) : dHash compare la
// luminance de pixels adjacents après réduction à 9x8 en niveaux de gris.
// Nettement plus simple à implémenter correctement en Deno (pas de DCT à
// coder à la main) pour une robustesse comparable en pratique face à la
// recompression/léger recadrage, avec le même format 64 bits et le même
// seuil de distance de Hamming que demandé.
// Note : imagescript indexe les pixels à partir de 1 (pas de 0) —
// getRGBAAt(1, 1) est le premier pixel, d'où les bornes 1..8 ci-dessous.
async function calculerDHash(bytes: Uint8Array): Promise<string | null> {
  try {
    const img = await Image.decode(bytes);
    const resized = img.resize(9, 8) ?? img;
    let bits = "";
    for (let y = 1; y <= 8; y++) {
      for (let x = 1; x <= 8; x++) {
        const p1 = resized.getRGBAAt(x, y);
        const p2 = resized.getRGBAAt(x + 1, y);
        const l1 = 0.299 * p1[0] + 0.587 * p1[1] + 0.114 * p1[2];
        const l2 = 0.299 * p2[0] + 0.587 * p2[1] + 0.114 * p2[2];
        bits += l1 > l2 ? "1" : "0";
      }
    }
    return bits;
  } catch (e) {
    console.error("calculerDHash a échoué:", e);
    return null;
  }
}

function distanceHamming(a: string, b: string): number {
  let d = 0;
  for (let i = 0; i < a.length && i < b.length; i++) {
    if (a[i] !== b[i]) d++;
  }
  return d;
}

function mimeTypeDepuisUrl(url: string): string {
  const sansQuery = url.split("?")[0].toLowerCase();
  if (sansQuery.endsWith(".png")) return "image/png";
  if (sansQuery.endsWith(".webp")) return "image/webp";
  return "image/jpeg";
}

function calculerRiskScore(
  fraudMatch: boolean,
  categories: Categories | null,
  geminiErreur: string | null,
): number {
  let score = 0;
  if (fraudMatch) score = Math.max(score, 55);
  if (categories) {
    if (categories.arnaque_suspectee) score = Math.max(score, 45);
    if (categories.violence) score = Math.max(score, 90);
    if (categories.stupefiants) score = Math.max(score, 90);
    if (categories.pornographie) score = Math.max(score, 95);
  }
  // Échec/absence de clé Gemini : jamais de publication aveugle.
  if (geminiErreur) score = Math.max(score, 40);
  return Math.min(score, 100);
}

function decisionDepuisScore(score: number): "publie" | "a_verifier" | "bloque" {
  if (score >= 70) return "bloque";
  if (score >= 30) return "a_verifier";
  return "publie";
}

serve(async (req) => {
  try {
    const payload = await req.json();
    const table: string = payload.table;
    const record: Record<string, unknown> = payload.record ?? {};
    const annonceType: AnnonceType = table === "articles" ? "article" : "logement";
    const tableName = table === "articles" ? "articles" : "logements";
    const annonceId = String(record.id);
    const vendeurId = String(
      annonceType === "article" ? record.vendeur_id : record.proprietaire_id,
    );
    const photos: string[] = Array.isArray(record.photos)
      ? (record.photos as string[])
      : [];
    const titre = String(record.titre ?? "");
    const description = String(record.description ?? "");

    // 1. Téléchargement des photos une seule fois (réutilisées pour le hash
    // et pour l'appel Gemini).
    const images: { url: string; bytes: Uint8Array | null }[] = [];
    for (const url of photos) {
      try {
        const res = await fetch(url);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        images.push({ url, bytes: new Uint8Array(await res.arrayBuffer()) });
      } catch (e) {
        console.error(`Téléchargement échoué pour ${url}:`, e);
        images.push({ url, bytes: null });
      }
    }

    // 2. Hash perceptuel + détection de réutilisation frauduleuse
    let fraudMatch = false;
    let fraudMatchAnnonceId: string | null = null;
    const nouveauxHashes: { url: string; hash: string }[] = [];

    const { data: hashesExistants } = await supabaseAdmin
      .from("image_hashes")
      .select("annonce_id, vendeur_id, hash")
      .neq("vendeur_id", vendeurId)
      .order("created_at", { ascending: false })
      .limit(MAX_HASHES_COMPARES);

    for (const img of images) {
      if (!img.bytes) continue;
      const hash = await calculerDHash(img.bytes);
      if (!hash) continue;
      nouveauxHashes.push({ url: img.url, hash });
      if (!fraudMatch) {
        for (const existant of hashesExistants ?? []) {
          if (distanceHamming(hash, existant.hash as string) <= HAMMING_SEUIL) {
            fraudMatch = true;
            fraudMatchAnnonceId = existant.annonce_id as string;
            break;
          }
        }
      }
    }

    if (nouveauxHashes.length > 0) {
      await supabaseAdmin.from("image_hashes").insert(
        nouveauxHashes.map((h) => ({
          annonce_id: annonceId,
          annonce_type: annonceType,
          vendeur_id: vendeurId,
          image_url: h.url,
          hash: h.hash,
        })),
      );
    }

    // 3. Classification de contenu via Gemini (texte + jusqu'à 5 images)
    let categories: Categories | null = null;
    let geminiErreur: string | null = null;

    if (!GEMINI_API_KEY) {
      geminiErreur = "GEMINI_API_KEY non configurée";
    } else {
      try {
        const parts: Record<string, unknown>[] = [{
          text:
            "Tu es un modérateur de contenu pour Mboa, une marketplace étudiante " +
            "à Sangmelima (Cameroun) de logements et d'articles d'occasion. " +
            "Analyse ce titre, cette description et ces photos d'annonce, et " +
            "réponds UNIQUEMENT avec un JSON strict de la forme " +
            '{"pornographie":boolean,"violence":boolean,"stupefiants":boolean,' +
            '"arnaque_suspectee":boolean}. ' +
            "N'utilise JAMAIS le prix comme signal : les prix varient légitimement " +
            "d'un quartier à l'autre et ne doivent jamais influencer ta réponse, " +
            "y compris pour arnaque_suspectee (base ce champ uniquement sur des " +
            "signaux de contenu : texte incohérent avec les photos, demande de " +
            "paiement suspecte, contenu manifestement trompeur).\n\n" +
            `Titre: ${titre}\nDescription: ${description}`,
        }];
        for (const img of images.slice(0, MAX_IMAGES_GEMINI)) {
          if (!img.bytes) continue;
          parts.push({
            inline_data: {
              mime_type: mimeTypeDepuisUrl(img.url),
              data: encodeBase64(img.bytes),
            },
          });
        }

        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), GEMINI_TIMEOUT_MS);
        let res: Response;
        try {
          res = await fetch(
            `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
            {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                contents: [{ parts }],
                generationConfig: { responseMimeType: "application/json" },
              }),
              signal: controller.signal,
            },
          );
        } finally {
          clearTimeout(timeoutId);
        }

        if (!res.ok) throw new Error(`Gemini HTTP ${res.status}`);
        const data = await res.json();
        const texte = data?.candidates?.[0]?.content?.parts?.[0]?.text;
        if (!texte) throw new Error("Réponse Gemini vide");
        const parsed = JSON.parse(texte);
        categories = {
          pornographie: Boolean(parsed.pornographie),
          violence: Boolean(parsed.violence),
          stupefiants: Boolean(parsed.stupefiants),
          arnaque_suspectee: Boolean(parsed.arnaque_suspectee),
        };
      } catch (e) {
        geminiErreur = String(e);
      }
    }

    // 4. Score de risque & décision
    const riskScore = calculerRiskScore(fraudMatch, categories, geminiErreur);
    const decision = decisionDepuisScore(riskScore);

    // 5. Mise à jour de l'annonce (service_role : voir migration pour le
    // correctif de proteger_colonnes_confiance_* qui autorise cette écriture)
    const signalementsActuels = Number(record.signalements ?? 0);
    await supabaseAdmin.from(tableName).update({
      statut_moderation: decision,
      ...(decision !== "publie" ? { signalements: signalementsActuels + 1 } : {}),
    }).eq("id", annonceId);

    // 6. Journal de modération (consulté par admin_signalements_screen)
    await supabaseAdmin.from("moderation_ia").insert({
      annonce_id: annonceId,
      annonce_type: annonceType,
      risk_score: riskScore,
      decision,
      fraud_match: fraudMatch,
      fraud_match_annonce_id: fraudMatchAnnonceId,
      categories: categories ?? {},
      erreur: geminiErreur,
    });

    // 7. Signalement automatique si l'annonce nécessite une vérification
    if (decision !== "publie") {
      const raisons: string[] = [];
      if (fraudMatch) raisons.push("photos réutilisées d'une autre annonce");
      if (categories?.pornographie) raisons.push("contenu pornographique");
      if (categories?.violence) raisons.push("contenu violent");
      if (categories?.stupefiants) raisons.push("stupéfiants");
      if (categories?.arnaque_suspectee) raisons.push("arnaque suspectée");
      if (geminiErreur) raisons.push("analyse IA incomplète (vérification manuelle requise)");

      const raisonsTexte = raisons.length > 0 ? raisons.join(", ") : "à vérifier";
      await supabaseAdmin.from("signalements").insert({
        signaleur_id: null,
        cible_type: "annonce",
        cible_id: annonceId,
        raison: "detection_ia",
        description: `Score de risque ${riskScore}/100 — ${raisonsTexte}.`,
      });
    }

    return new Response(
      JSON.stringify({ annonce_id: annonceId, risk_score: riskScore, decision }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
