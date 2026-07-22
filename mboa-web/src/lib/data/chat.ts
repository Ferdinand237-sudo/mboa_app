import { createClient } from "@/lib/supabase/server";

// Miroir de _chargerConversations (chat_screen.dart).
export type ConversationItem = {
  id: string;
  autreId: string;
  autreNom: string;
  autrePhotoUrl: string | null;
  autreVerified: boolean;
  annonceId: string | null;
  annonceType: "logement" | "article" | null;
  annonceTitre: string | null;
  dernierMessage: string | null;
  dernierMessageDate: string | null;
  nbNonLu: number;
};

export async function getConversations(userId: string): Promise<ConversationItem[]> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from("conversations")
    .select("id, participants, annonce_id, annonce_type, dernier_message, dernier_message_date, non_lu")
    .contains("participants", [userId])
    .not("dernier_message", "is", null)
    .order("dernier_message_date", { ascending: false });

  if (error || !data || data.length === 0) {
    if (error) console.error("getConversations", error.message);
    return [];
  }

  type Row = {
    id: string;
    participants: string[];
    annonce_id: string | null;
    annonce_type: "logement" | "article" | null;
    dernier_message: string | null;
    dernier_message_date: string | null;
    non_lu: Record<string, number> | null;
  };
  const rows = data as unknown as Row[];

  const idsParticipants = [
    ...new Set(rows.map((c) => c.participants.find((id) => id !== userId) ?? userId)),
  ];
  const { data: usersData } = await supabase
    .from("users")
    .select("id, nom, photo_url, verified")
    .in("id", idsParticipants);
  const mapUsers = new Map((usersData ?? []).map((u) => [u.id, u]));

  const idsLogements = [
    ...new Set(rows.filter((c) => c.annonce_type === "logement" && c.annonce_id).map((c) => c.annonce_id as string)),
  ];
  const idsArticles = [
    ...new Set(rows.filter((c) => c.annonce_type === "article" && c.annonce_id).map((c) => c.annonce_id as string)),
  ];
  const mapTitres = new Map<string, string>();
  if (idsLogements.length > 0) {
    const { data: logs } = await supabase.from("logements").select("id, titre").in("id", idsLogements);
    for (const l of logs ?? []) mapTitres.set(l.id, l.titre ?? "");
  }
  if (idsArticles.length > 0) {
    const { data: arts } = await supabase.from("articles").select("id, titre").in("id", idsArticles);
    for (const a of arts ?? []) mapTitres.set(a.id, a.titre ?? "");
  }

  return rows.map((c) => {
    const autreId = c.participants.find((id) => id !== userId) ?? userId;
    const autre = mapUsers.get(autreId);
    return {
      id: c.id,
      autreId,
      autreNom: autre?.nom ?? "Utilisateur",
      autrePhotoUrl: autre?.photo_url ?? null,
      autreVerified: autre?.verified === true,
      annonceId: c.annonce_id,
      annonceType: c.annonce_type,
      annonceTitre: c.annonce_id ? (mapTitres.get(c.annonce_id) ?? null) : null,
      dernierMessage: c.dernier_message,
      dernierMessageDate: c.dernier_message_date,
      nbNonLu: c.non_lu?.[userId] ?? 0,
    };
  });
}

// Miroir des données passées à ConversationScreen (chat_screen.dart) : sur
// web on les recharge depuis l'id de conversation plutôt que de les
// transmettre depuis l'écran précédent.
export type ConversationDetail = {
  id: string;
  autreId: string;
  autreNom: string;
  autrePhotoUrl: string | null;
  autreVerified: boolean;
  annonceId: string | null;
  annonceType: "logement" | "article" | null;
  sujet: string;
};

export async function getConversationDetail(id: string, userId: string): Promise<ConversationDetail | null> {
  const supabase = await createClient();

  const { data: conv, error } = await supabase
    .from("conversations")
    .select("id, participants, annonce_id, annonce_type")
    .eq("id", id)
    .single();

  if (error || !conv || !conv.participants.includes(userId)) return null;

  const autreId = (conv.participants as string[]).find((p) => p !== userId) ?? userId;
  const { data: autre } = await supabase
    .from("users")
    .select("nom, photo_url, verified")
    .eq("id", autreId)
    .single();

  let annonceTitre: string | null = null;
  if (conv.annonce_id && conv.annonce_type) {
    const table = conv.annonce_type === "logement" ? "logements" : "articles";
    const { data: annonce } = await supabase.from(table).select("titre").eq("id", conv.annonce_id).maybeSingle();
    annonceTitre = annonce?.titre ?? null;
  }

  const emoji = conv.annonce_type === "logement" ? "🏠" : "🛒";
  const sujet =
    annonceTitre && annonceTitre.length > 0
      ? `${emoji} ${annonceTitre}`
      : conv.annonce_type === "logement"
        ? "🏠 Logement"
        : conv.annonce_type === "article"
          ? "🛒 Article"
          : "💬 Conversation";

  return {
    id: conv.id,
    autreId,
    autreNom: autre?.nom ?? "Utilisateur",
    autrePhotoUrl: autre?.photo_url ?? null,
    autreVerified: autre?.verified === true,
    annonceId: conv.annonce_id,
    annonceType: conv.annonce_type,
    sujet,
  };
}

export type MessageRow = {
  id: string;
  conversationId: string;
  expediteurId: string;
  texte: string;
  lu: boolean;
  dateEnvoi: string;
};

export async function getMessages(conversationId: string): Promise<MessageRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("messages")
    .select("id, conversation_id, expediteur_id, texte, lu, date_envoi")
    .eq("conversation_id", conversationId)
    .order("date_envoi", { ascending: true });

  if (error || !data) return [];
  return data.map((m) => ({
    id: m.id,
    conversationId: m.conversation_id,
    expediteurId: m.expediteur_id,
    texte: m.texte ?? "",
    lu: m.lu === true,
    dateEnvoi: m.date_envoi,
  }));
}
