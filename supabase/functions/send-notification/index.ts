// Edge Function déclenchée par un Database Webhook Supabase sur INSERT
// dans public.messages. Envoie une notification push (Firebase Cloud
// Messaging) au destinataire de la conversation via son fcm_token.
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

serve(async (req) => {
  try {
    const payload = await req.json();
    // Le Database Webhook Supabase envoie { type, table, record, ... }
    const record = payload.record ?? payload;

    const conversationId = record.conversation_id;
    const expediteurId = record.expediteur_id;
    const texte: string = record.texte ?? "";

    const { data: conversation } = await supabaseAdmin
      .from("conversations")
      .select("participants")
      .eq("id", conversationId)
      .single();

    const participants: string[] = conversation?.participants ?? [];
    const destinataireId = participants.find((id) => id !== expediteurId);
    if (!destinataireId) {
      return new Response(JSON.stringify({ skipped: "no_recipient" }), {
        status: 200,
      });
    }

    const [{ data: expediteur }, { data: destinataire }] = await Promise.all([
      supabaseAdmin.from("users").select("nom").eq("id", expediteurId)
        .single(),
      supabaseAdmin.from("users").select("fcm_token").eq(
        "id",
        destinataireId,
      ).single(),
    ]);

    if (!destinataire?.fcm_token) {
      return new Response(JSON.stringify({ skipped: "no_token" }), {
        status: 200,
      });
    }

    const resultat = await envoyerPush(
      destinataire.fcm_token,
      expediteur?.nom ?? "Nouveau message",
      texte.length > 100 ? `${texte.slice(0, 100)}…` : texte,
      { type: "message", conversation_id: String(conversationId) },
    );

    return new Response(JSON.stringify({ sent: true, resultat }), {
      status: 200,
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
    });
  }
});
