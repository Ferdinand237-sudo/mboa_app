import { createClient } from "@/lib/supabase/server";

// Miroir de _charger (notifications_screen.dart) : fusionne messages non lus
// et avis reçus, triés par date décroissante.
export type NotificationItem = {
  type: "message" | "avis";
  texte: string;
  date: string | null;
};

export async function getNotifications(userId: string): Promise<NotificationItem[]> {
  const supabase = await createClient();
  const resultats: NotificationItem[] = [];

  const { data: conversations } = await supabase
    .from("conversations")
    .select("dernier_message, dernier_message_date, non_lu")
    .contains("participants", [userId]);

  for (const conv of conversations ?? []) {
    const nonLu = conv.non_lu as Record<string, number> | null;
    const nb = nonLu && typeof nonLu[userId] === "number" ? nonLu[userId] : 0;
    if (nb > 0) {
      resultats.push({
        type: "message",
        texte: `${nb} nouveau${nb > 1 ? "x" : ""} message${nb > 1 ? "s" : ""} : ${conv.dernier_message ?? ""}`,
        date: conv.dernier_message_date,
      });
    }
  }

  const { data: avis } = await supabase
    .from("avis")
    .select("note, date_publication, auteur:users!auteur_id(nom)")
    .eq("cible_id", userId)
    .order("date_publication", { ascending: false })
    .limit(10);

  for (const a of (avis ?? []) as unknown as {
    note: number;
    date_publication: string;
    auteur: { nom: string | null } | null;
  }[]) {
    resultats.push({
      type: "avis",
      texte: `${a.auteur?.nom ?? "Un utilisateur"} vous a donné ${a.note} ⭐`,
      date: a.date_publication,
    });
  }

  resultats.sort((x, y) => {
    const dx = x.date ? new Date(x.date).getTime() : 0;
    const dy = y.date ? new Date(y.date).getTime() : 0;
    return dy - dx;
  });

  return resultats;
}
