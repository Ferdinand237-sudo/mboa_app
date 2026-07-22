import type { createClient } from "@/lib/supabase/client";

// Miroir de attendreDecisionModeration / afficherResultatModeration
// (publier_screen.dart) : attend la décision de l'Edge Function
// moderate-annonce sur la ligne fraîchement insérée via un canal realtime
// dédié, fermé dès réception ou au bout de 20s.
export async function attendreDecisionModeration(
  supabase: ReturnType<typeof createClient>,
  table: string,
  id: string,
): Promise<string | null> {
  return new Promise((resolve) => {
    let done = false;
    const channel = supabase
      .channel(`moderation_${table}_${id}`)
      .on(
        "postgres_changes",
        { event: "UPDATE", schema: "public", table, filter: `id=eq.${id}` },
        (payload) => {
          const statut = (payload.new as { statut_moderation?: string }).statut_moderation;
          if (statut && statut !== "en_attente" && !done) {
            done = true;
            supabase.removeChannel(channel);
            resolve(statut);
          }
        },
      )
      .subscribe();

    setTimeout(() => {
      if (!done) {
        done = true;
        supabase.removeChannel(channel);
        resolve(null);
      }
    }, 20000);
  });
}

export type ToneResultat = "success" | "warning" | "danger";

export function messageResultatModeration(
  decision: string | null,
  libelle: string,
): { message: string; tone: ToneResultat } {
  switch (decision) {
    case "publie":
      return { message: `✅ ${libelle} publié avec succès !`, tone: "success" };
    case "a_verifier":
      return {
        message: `🔍 ${libelle} enregistré, en cours de vérification avant publication.`,
        tone: "warning",
      };
    case "bloque":
      return {
        message: `⛔ ${libelle} refusé par la modération. Consulte « Mes annonces » pour plus de détails.`,
        tone: "danger",
      };
    default:
      return {
        message: `⏳ ${libelle} enregistré, analyse en cours. Tu seras notifié une fois validée.`,
        tone: "warning",
      };
  }
}
