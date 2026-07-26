import { createClient } from "@/lib/supabase/server";

// Miroir de _chargerConversations (chat_screen.dart), étendu pour Assistant
// Mboa (voir migration 20260726000000_assistant_mboa.sql) : une conversation
// support par compte non-admin (participants = [userId] uniquement, pas
// d'admin fixe), visible dans la liste de tous les admins tant qu'aucun n'a
// répondu, puis figée sur le premier qui répond (assigned_admin_id).
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
  isSupport: boolean;
  assigneAMoi: boolean;
};

const NOM_ASSISTANT = "Assistant Mboa";

type Row = {
  id: string;
  participants: string[];
  annonce_id: string | null;
  annonce_type: "logement" | "article" | null;
  dernier_message: string | null;
  dernier_message_date: string | null;
  non_lu: Record<string, number> | null;
  is_support: boolean;
  assigned_admin_id: string | null;
};

async function garnirTitresAnnonces(
  supabase: Awaited<ReturnType<typeof createClient>>,
  rows: Row[],
): Promise<Map<string, string>> {
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
  return mapTitres;
}

// Liste d'un étudiant/vendeur/ambassadeur : conversations classiques +
// toujours sa propre conversation Assistant Mboa (même sans message envoyé
// encore, pour qu'elle serve de point d'entrée visible vers le support).
async function getConversationsMembre(userId: string): Promise<ConversationItem[]> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from("conversations")
    .select("id, participants, annonce_id, annonce_type, dernier_message, dernier_message_date, non_lu, is_support, assigned_admin_id")
    .contains("participants", [userId])
    .order("dernier_message_date", { ascending: false, nullsFirst: false });

  if (error || !data) {
    if (error) console.error("getConversationsMembre", error.message);
    return [];
  }

  // Filtré côté client (pas côté requête) : une conversation classique sans
  // premier message est une entrée fantôme à masquer, mais la conversation
  // Assistant Mboa doit rester visible même vide, comme point d'entrée.
  const rows = (data as unknown as Row[]).filter((c) => c.dernier_message !== null || c.is_support);

  const idsAutres = [
    ...new Set(rows.filter((c) => !c.is_support).map((c) => c.participants.find((id) => id !== userId) ?? userId)),
  ];
  const { data: usersData } = await supabase.from("users").select("id, nom, photo_url, verified").in("id", idsAutres);
  const mapUsers = new Map((usersData ?? []).map((u) => [u.id, u]));
  const mapTitres = await garnirTitresAnnonces(supabase, rows);

  return rows.map((c) => {
    if (c.is_support) {
      return {
        id: c.id,
        autreId: userId,
        autreNom: NOM_ASSISTANT,
        autrePhotoUrl: null,
        autreVerified: true,
        annonceId: null,
        annonceType: null,
        annonceTitre: null,
        dernierMessage: c.dernier_message,
        dernierMessageDate: c.dernier_message_date,
        nbNonLu: c.non_lu?.[userId] ?? 0,
        isSupport: true,
        assigneAMoi: false,
      };
    }
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
      isSupport: false,
      assigneAMoi: false,
    };
  });
}

// Liste d'un admin : uniquement les conversations Assistant Mboa non
// assignées ou assignées à lui — jamais les conversations classiques entre
// étudiants/vendeurs, et jamais celles déjà prises par un autre admin.
async function getConversationsAdmin(adminId: string): Promise<ConversationItem[]> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from("conversations")
    .select("id, participants, dernier_message, dernier_message_date, non_lu, assigned_admin_id")
    .eq("is_support", true)
    .or(`assigned_admin_id.is.null,assigned_admin_id.eq.${adminId}`)
    .not("dernier_message", "is", null)
    .order("dernier_message_date", { ascending: false, nullsFirst: false });

  if (error || !data) {
    if (error) console.error("getConversationsAdmin", error.message);
    return [];
  }

  const rows = data as unknown as Pick<Row, "id" | "participants" | "dernier_message" | "dernier_message_date" | "non_lu" | "assigned_admin_id">[];
  const idsEtudiants = [...new Set(rows.map((c) => c.participants[0]))];
  const { data: usersData } = await supabase.from("users").select("id, nom, photo_url, verified").in("id", idsEtudiants);
  const mapUsers = new Map((usersData ?? []).map((u) => [u.id, u]));

  return rows.map((c) => {
    const etudiantId = c.participants[0];
    const etudiant = mapUsers.get(etudiantId);
    const assigneAMoi = c.assigned_admin_id === adminId;
    const cleNonLu = assigneAMoi ? adminId : "non_assigne";
    return {
      id: c.id,
      autreId: etudiantId,
      autreNom: etudiant?.nom ?? "Utilisateur",
      autrePhotoUrl: etudiant?.photo_url ?? null,
      autreVerified: etudiant?.verified === true,
      annonceId: null,
      annonceType: null,
      annonceTitre: null,
      dernierMessage: c.dernier_message,
      dernierMessageDate: c.dernier_message_date,
      nbNonLu: c.non_lu?.[cleNonLu] ?? 0,
      isSupport: true,
      assigneAMoi,
    };
  });
}

export async function getConversations(userId: string, role: string): Promise<ConversationItem[]> {
  return role === "admin" ? getConversationsAdmin(userId) : getConversationsMembre(userId);
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
  isSupport: boolean;
  assignedAdminId: string | null;
};

export async function getConversationDetail(id: string, userId: string): Promise<ConversationDetail | null> {
  const supabase = await createClient();

  const { data: conv, error } = await supabase
    .from("conversations")
    .select("id, participants, annonce_id, annonce_type, is_support, assigned_admin_id")
    .eq("id", id)
    .single();

  if (error || !conv) return null;

  // Un membre (non-admin) ne peut voir que sa propre conversation ; un admin
  // passe par les policies RLS dédiées (is_support) pour les siennes/non
  // assignées, indépendamment de participants.
  const estMembre = conv.participants.includes(userId);
  if (!estMembre && !conv.is_support) return null;

  if (conv.is_support) {
    if (estMembre) {
      return {
        id: conv.id,
        autreId: userId,
        autreNom: NOM_ASSISTANT,
        autrePhotoUrl: null,
        autreVerified: true,
        annonceId: null,
        annonceType: null,
        sujet: "💬 Support Mboa",
        isSupport: true,
        assignedAdminId: conv.assigned_admin_id,
      };
    }
    const etudiantId = (conv.participants as string[])[0];
    const { data: etudiant } = await supabase.from("users").select("nom, photo_url, verified").eq("id", etudiantId).single();
    return {
      id: conv.id,
      autreId: etudiantId,
      autreNom: etudiant?.nom ?? "Utilisateur",
      autrePhotoUrl: etudiant?.photo_url ?? null,
      autreVerified: etudiant?.verified === true,
      annonceId: null,
      annonceType: null,
      sujet: "💬 Assistant Mboa",
      isSupport: true,
      assignedAdminId: conv.assigned_admin_id,
    };
  }

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
    isSupport: false,
    assignedAdminId: null,
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
