// Edge Function déclenchée par un Database Webhook Supabase sur INSERT
// dans public.logements ET public.articles (deux webhooks pointant vers
// la même fonction — le payload contient le nom de la table). Notifie
// chaque utilisateur dont une alerte de recherche enregistrée
// (table alertes_recherche) correspond à la nouvelle annonce.
//
// Mêmes secrets que send-notification : FIREBASE_PROJECT_ID et
// FIREBASE_SERVICE_ACCOUNT_JSON.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { GoogleAuth } from "npm:google-auth-library@9";

const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID") ?? "";
const FIREBASE_SERVICE_ACCOUNT = JSON.parse(
  Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON") ?? "{}",
);

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

async function obtenirJetonAcces(): Promise<string> {
  const auth = new GoogleAuth({
    credentials: FIREBASE_SERVICE_ACCOUNT,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });
  const client = await auth.getClient();
  const token = await client.getAccessToken();
  return token.token as string;
}

async function envoyerPush(
  fcmToken: string,
  titre: string,
  corps: string,
  data: Record<string, string> = {},
) {
  const jeton = await obtenirJetonAcces();
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${jeton}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: { title: titre, body: corps },
          data,
          android: { priority: "high" },
        },
      }),
    },
  );
  return res.json();
}

function correspond(
  type: "logement" | "article",
  criteres: Record<string, unknown>,
  annonce: Record<string, unknown>,
): boolean {
  if (type === "logement") {
    if (
      criteres.type && criteres.type !== "Tous" &&
      criteres.type !== annonce.type
    ) return false;
    if (
      criteres.prixMax != null &&
      Number(annonce.prix) > Number(criteres.prixMax)
    ) return false;
    return true;
  }
  if (
    criteres.categorie && criteres.categorie !== "Tous" &&
    criteres.categorie !== annonce.categorie
  ) return false;
  if (
    criteres.etat && criteres.etat !== "Tous" && criteres.etat !== annonce.etat
  ) return false;
  return true;
}

serve(async (req) => {
  try {
    const payload = await req.json();
    const table: string = payload.table;
    const annonce = payload.record ?? {};
    const type: "logement" | "article" = table === "articles"
      ? "article"
      : "logement";

    const { data: alertes } = await supabaseAdmin
      .from("alertes_recherche")
      .select("user_id, libelle, criteres")
      .eq("type", type);

    const correspondantes = (alertes ?? []).filter((a) =>
      correspond(type, a.criteres ?? {}, annonce)
    );

    if (correspondantes.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }), { status: 200 });
    }

    const userIds = [...new Set(correspondantes.map((a) => a.user_id))];
    const { data: utilisateurs } = await supabaseAdmin
      .from("users")
      .select("id, fcm_token")
      .in("id", userIds);

    const tokensParUser = new Map(
      (utilisateurs ?? []).map((u) => [u.id, u.fcm_token]),
    );

    const titreAnnonce = annonce.titre ?? "Nouvelle annonce";
    let envoyes = 0;
    for (const alerte of correspondantes) {
      const token = tokensParUser.get(alerte.user_id);
      if (!token) continue;
      await envoyerPush(
        token,
        "🔔 Nouvelle annonce pour votre alerte",
        `${alerte.libelle} : ${titreAnnonce}`,
        { type: "alerte", annonce_type: type },
      );
      envoyes++;
    }

    return new Response(JSON.stringify({ sent: envoyes }), { status: 200 });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
    });
  }
});
