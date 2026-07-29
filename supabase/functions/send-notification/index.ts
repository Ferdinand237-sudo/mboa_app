// Edge Function déclenchée par des Database Webhooks Supabase (net.http_post
// depuis des triggers SQL) sur INSERT dans public.messages, ainsi que sur
// public.demandes_compte et public.signalements (diffusion à tous les
// admins) — envoie une notification push (Firebase Cloud Messaging).
//
// Secrets requis (à configurer dans le dashboard Supabase, Edge Functions
// > send-notification > Secrets, ou via `supabase secrets set`) :
//   FIREBASE_PROJECT_ID           id du projet Firebase
//   FIREBASE_SERVICE_ACCOUNT_JSON contenu complet du fichier de clé de
//                                 service (compte de service) téléchargé
//                                 depuis Firebase > Paramètres du projet
//                                 > Comptes de service

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

// Diffusion à tous les administrateurs disposant d'un jeton FCM (même
// principe que le push individuel, un envoi par admin).
async function notifierTousAdmins(
  titre: string,
  corps: string,
  data: Record<string, string> = {},
) {
  // role='admin' OU privilège superposé est_admin (voir refonte des rôles,
  // HISTORIQUE_PROJET_MBOA.md §4.9) — un filtre role seul manquait tout
  // admin par privilège, jamais notifié par push.
  const { data: admins } = await supabaseAdmin
    .from("users")
    .select("fcm_token")
    .or("role.eq.admin,est_admin.eq.true")
    .not("fcm_token", "is", null);

  const resultats = [];
  for (const admin of admins ?? []) {
    if (admin.fcm_token) {
      resultats.push(await envoyerPush(admin.fcm_token, titre, corps, data));
    }
  }
  return resultats;
}

async function gererNouveauMessage(record: Record<string, unknown>) {
  const conversationId = record.conversation_id;
  const expediteurId = record.expediteur_id as string;
  const texte = String(record.texte ?? "");
  const corps = texte.length > 100 ? `${texte.slice(0, 100)}…` : texte;

  const { data: conversation } = await supabaseAdmin
    .from("conversations")
    .select("participants, is_support, assigned_admin_id")
    .eq("id", conversationId)
    .single();

  const participants: string[] = conversation?.participants ?? [];
  const destinataireId = participants.find((id) => id !== expediteurId);

  // Conversation Assistant Mboa : participants ne contient que l'étudiant,
  // donc un message envoyé par l'étudiant lui-même ne trouve "personne
  // d'autre" via la logique habituelle. Route vers l'admin déjà assigné, ou
  // diffuse à tous les admins tant que personne n'a répondu.
  if (!destinataireId && conversation?.is_support) {
    const { data: expediteur } = await supabaseAdmin.from("users").select(
      "nom",
    ).eq("id", expediteurId).single();
    const titre = `💬 ${expediteur?.nom ?? "Un étudiant"} (Assistant Mboa)`;
    const data = { type: "message", conversation_id: String(conversationId) };

    if (conversation.assigned_admin_id) {
      const { data: admin } = await supabaseAdmin.from("users").select(
        "fcm_token",
      ).eq("id", conversation.assigned_admin_id).single();
      if (!admin?.fcm_token) return { skipped: "no_token" };
      const resultat = await envoyerPush(admin.fcm_token, titre, corps, data);
      return { sent: true, resultat };
    }
    const resultats = await notifierTousAdmins(titre, corps, data);
    return { sent: true, resultats };
  }

  if (!destinataireId) return { skipped: "no_recipient" };

  const [{ data: expediteur }, { data: destinataire }] = await Promise.all([
    supabaseAdmin.from("users").select("nom").eq("id", expediteurId).single(),
    supabaseAdmin.from("users").select("fcm_token").eq("id", destinataireId)
      .single(),
  ]);

  if (!destinataire?.fcm_token) return { skipped: "no_token" };

  const resultat = await envoyerPush(
    destinataire.fcm_token,
    expediteur?.nom ?? "Nouveau message",
    corps,
    { type: "message", conversation_id: String(conversationId) },
  );
  return { sent: true, resultat };
}

async function gererNouvelleDemandeCompte(record: Record<string, unknown>) {
  const nom = String(record.nom ?? "Un utilisateur");
  const typeActivite = String(record.type_activite ?? "vendeur");
  const resultats = await notifierTousAdmins(
    "📨 Nouvelle demande de compte",
    `${nom} souhaite devenir ${typeActivite}`,
    { type: "demande", demande_id: String(record.id) },
  );
  return { sent: true, resultats };
}

async function gererNouveauSignalement(record: Record<string, unknown>) {
  const estIa = record.raison === "detection_ia";
  const resultats = await notifierTousAdmins(
    estIa ? "🤖 Détection IA — annonce à vérifier" : "🚩 Nouveau signalement",
    String(record.description ?? record.raison ?? "À vérifier"),
    { type: "signalement", signalement_id: String(record.id) },
  );
  return { sent: true, resultats };
}

serve(async (req) => {
  try {
    const payload = await req.json();
    // Le trigger SQL envoie { table, record }.
    const table: string | undefined = payload.table;
    const record = payload.record ?? payload;

    let resultat: Record<string, unknown>;
    if (table === "demandes_compte") {
      resultat = await gererNouvelleDemandeCompte(record);
    } else if (table === "signalements") {
      resultat = await gererNouveauSignalement(record);
    } else {
      resultat = await gererNouveauMessage(record);
    }

    return new Response(JSON.stringify(resultat), { status: 200 });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
    });
  }
});
