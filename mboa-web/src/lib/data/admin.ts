import { createClient } from "@/lib/supabase/server";

// Miroir de _chargerStats (admin_screen.dart) : comptages via head+count
// plutôt que de rapatrier toutes les lignes comme le fait le client Dart.
export type AdminStats = {
  users: number;
  logements: number;
  articles: number;
  signalements: number;
  demandes: number;
};

export async function getAdminStats(): Promise<AdminStats> {
  const supabase = await createClient();
  const [users, logements, articles, signalements, demandes] = await Promise.all([
    supabase.from("users").select("id", { count: "exact", head: true }),
    supabase.from("logements").select("id", { count: "exact", head: true }),
    supabase.from("articles").select("id", { count: "exact", head: true }),
    supabase.from("signalements").select("id", { count: "exact", head: true }).eq("statut", "en-attente"),
    supabase.from("demandes_compte").select("id", { count: "exact", head: true }).eq("statut", "en-attente"),
  ]);
  return {
    users: users.count ?? 0,
    logements: logements.count ?? 0,
    articles: articles.count ?? 0,
    signalements: signalements.count ?? 0,
    demandes: demandes.count ?? 0,
  };
}

// Miroir de _chargerUsers (admin_users_screen.dart).
export type AdminUser = {
  id: string;
  nom: string;
  email: string;
  role: string;
  verified: boolean;
  actif: boolean;
  statutVerification: string | null;
};

export async function getAdminUsers(): Promise<AdminUser[]> {
  const supabase = await createClient();
  const [usersRes, verifsRes] = await Promise.all([
    supabase
      .from("users")
      .select("id, nom, email, role, verified, actif")
      .order("date_inscription", { ascending: false }),
    supabase.from("verifications_terrain").select("user_id, statut"),
  ]);

  const mapVerif = new Map((verifsRes.data ?? []).map((v) => [v.user_id as string, v.statut as string]));

  return (usersRes.data ?? []).map((u) => ({
    id: u.id,
    nom: u.nom ?? "Inconnu",
    email: u.email ?? "",
    role: u.role ?? "visiteur",
    verified: u.verified === true,
    actif: u.actif !== false,
    statutVerification: mapVerif.get(u.id) ?? null,
  }));
}

// Miroir de _chargerLogements/_chargerArticles (admin_annonces_screen.dart).
export type AdminAnnonce = {
  id: string;
  table: "logements" | "articles";
  titre: string;
  prix: number;
  boosted: boolean;
  statut: string;
  signalements: number;
  vendeurNom: string | null;
  infoSecondaire: string;
};

export async function getAdminAnnonces(): Promise<{ logements: AdminAnnonce[]; articles: AdminAnnonce[] }> {
  const supabase = await createClient();
  const [logsRes, artsRes] = await Promise.all([
    supabase
      .from("logements")
      .select("id, titre, prix, boosted, statut, signalements, quartier, proprietaire:users!proprietaire_id(nom)")
      .order("date_publication", { ascending: false }),
    supabase
      .from("articles")
      .select("id, titre, prix, boosted, statut, signalements, categorie, vendeur:users!vendeur_id(nom)")
      .order("date_publication", { ascending: false }),
  ]);

  type Row = {
    id: string;
    titre: string | null;
    prix: number | null;
    boosted: boolean | null;
    statut: string | null;
    signalements: number | null;
    quartier?: string | null;
    categorie?: string | null;
  };

  const logements = ((logsRes.data ?? []) as unknown as (Row & { proprietaire: { nom: string } | null })[]).map(
    (l) => ({
      id: l.id,
      table: "logements" as const,
      titre: l.titre ?? "",
      prix: l.prix ?? 0,
      boosted: l.boosted === true,
      statut: l.statut ?? "disponible",
      signalements: l.signalements ?? 0,
      vendeurNom: l.proprietaire?.nom ?? null,
      infoSecondaire: l.quartier ?? "",
    }),
  );

  const articles = ((artsRes.data ?? []) as unknown as (Row & { vendeur: { nom: string } | null })[]).map((a) => ({
    id: a.id,
    table: "articles" as const,
    titre: a.titre ?? "",
    prix: a.prix ?? 0,
    boosted: a.boosted === true,
    statut: a.statut ?? "disponible",
    signalements: a.signalements ?? 0,
    vendeurNom: a.vendeur?.nom ?? null,
    infoSecondaire: a.categorie ?? "",
  }));

  return { logements, articles };
}

// Miroir de _chargerSignalements (admin_signalements_screen.dart).
export type AdminSignalement = {
  id: string;
  statut: string;
  cibleType: string;
  cibleId: string;
  raison: string;
  description: string | null;
  estDetectionIa: boolean;
  signaleurNom: string | null;
  dateSignalement: string;
};

export async function getAdminSignalements(): Promise<AdminSignalement[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("signalements")
    .select("id, statut, cible_type, cible_id, raison, description, date_signalement, signaleur:users!signaleur_id(nom)")
    .order("date_signalement", { ascending: false });

  if (error || !data) return [];

  return (data as unknown as {
    id: string;
    statut: string | null;
    cible_type: string | null;
    cible_id: string;
    raison: string | null;
    description: string | null;
    date_signalement: string;
    signaleur: { nom: string } | null;
  }[]).map((s) => ({
    id: s.id,
    statut: s.statut ?? "en-attente",
    cibleType: s.cible_type ?? "annonce",
    cibleId: s.cible_id,
    raison: s.raison ?? "",
    description: s.description,
    estDetectionIa: s.raison === "detection_ia",
    signaleurNom: s.signaleur?.nom ?? null,
    dateSignalement: s.date_signalement,
  }));
}

// Miroir de _chargerDemandes (admin_demandes_screen.dart).
export type AdminDemande = {
  id: string;
  userId: string | null;
  nom: string;
  email: string;
  whatsapp: string;
  typeActivite: string;
  description: string;
  statut: string;
  createdAt: string;
};

export async function getAdminDemandes(): Promise<AdminDemande[]> {
  const supabase = await createClient();
  const { data, error } = await supabase.from("demandes_compte").select().order("created_at", { ascending: false });
  if (error || !data) return [];
  return data.map((d) => ({
    id: d.id,
    userId: d.user_id ?? null,
    nom: d.nom ?? "",
    email: d.email ?? "",
    whatsapp: d.whatsapp ?? "",
    typeActivite: d.type_activite ?? "",
    description: d.description ?? "",
    statut: d.statut ?? "en-attente",
    createdAt: d.created_at,
  }));
}

// Miroir de _charger (admin_verifications_screen.dart).
export type AdminVerification = {
  id: string;
  statut: string;
  proprietaireNom: string | null;
  proprietaireContact: string | null;
  ambassadeurNom: string | null;
  conformiteBien: boolean | null;
  typeJustificatif: string | null;
};

export async function getAdminVerifications(): Promise<AdminVerification[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("verifications_terrain")
    .select(
      "id, statut, conformite_bien, type_justificatif, proprietaire:users!verifications_terrain_user_id_fkey(nom, telephone, email), ambassadeur:users!verifications_terrain_ambassadeur_id_fkey(nom)",
    )
    .order("created_at", { ascending: false });

  if (error || !data) return [];

  return (data as unknown as {
    id: string;
    statut: string | null;
    conformite_bien: boolean | null;
    type_justificatif: string | null;
    proprietaire: { nom: string; telephone: string | null; email: string } | null;
    ambassadeur: { nom: string } | null;
  }[]).map((v) => ({
    id: v.id,
    statut: v.statut ?? "en_attente_assignation",
    proprietaireNom: v.proprietaire?.nom ?? null,
    proprietaireContact: v.proprietaire?.telephone ?? v.proprietaire?.email ?? null,
    ambassadeurNom: v.ambassadeur?.nom ?? null,
    conformiteBien: v.conformite_bien,
    typeJustificatif: v.type_justificatif,
  }));
}

export type Ambassadeur = { id: string; nom: string };

export async function getAmbassadeurs(): Promise<Ambassadeur[]> {
  const supabase = await createClient();
  const { data } = await supabase.from("users").select("id, nom").eq("role", "ambassadeur");
  return (data ?? []).map((a) => ({ id: a.id, nom: a.nom ?? "" }));
}
