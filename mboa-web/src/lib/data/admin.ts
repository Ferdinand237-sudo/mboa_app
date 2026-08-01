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

// Miroir de _chargerUsers (admin_users_screen.dart). role reste l'identité
// de base (visiteur/vendeur) ; estAdmin/estAmbassadeur sont des privilèges
// superposables — voir la migration roles_multiples_admin_ambassadeur.
export type AdminUser = {
  id: string;
  nom: string;
  email: string;
  role: string;
  estAdmin: boolean;
  estAmbassadeur: boolean;
  verified: boolean;
  actif: boolean;
  statutVerification: string | null;
};

export async function getAdminUsers(): Promise<AdminUser[]> {
  const supabase = await createClient();
  const [usersRes, verifsRes] = await Promise.all([
    supabase
      .from("users")
      .select("id, nom, email, role, est_admin, est_ambassadeur, verified, actif")
      .order("date_inscription", { ascending: false }),
    supabase.from("verifications_terrain").select("user_id, statut"),
  ]);

  const mapVerif = new Map((verifsRes.data ?? []).map((v) => [v.user_id as string, v.statut as string]));

  return (usersRes.data ?? []).map((u) => ({
    id: u.id,
    nom: u.nom ?? "Inconnu",
    email: u.email ?? "",
    role: u.role ?? "visiteur",
    estAdmin: u.role === "admin" || u.est_admin === true,
    estAmbassadeur: u.role === "ambassadeur" || u.est_ambassadeur === true,
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
// Diagnostic par photo, issu de la dernière analyse moderate-annonce pour
// l'annonce ciblée — permet à l'admin de voir QUELLE photo précisément a
// déclenché la détection IA (réutilisation frauduleuse, catégorie Gemini)
// plutôt qu'un verdict global sans indice. `categories` reste vide si
// Gemini n'a pas pu être appelé (clé en quota, timeout...) : l'absence de
// détection par photo ne veut alors pas dire "photo propre", d'où
// `ignoree` pour les photos jamais réellement analysées (trop lourdes).
export type PhotoDiagnostic = {
  fraude: boolean;
  matchUrl: string | null;
  categories: string[];
  ignoree: boolean;
};

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
  // Photos de l'annonce ciblée (vide pour utilisateur/avis) : sans ça,
  // l'admin devait juger une détection IA "à vérifier" sans jamais voir
  // les photos en cause, ni pouvoir en exclure une précise avant de
  // republier — voir HISTORIQUE_PROJET_MBOA.md.
  photos: string[];
  // Table réelle de l'annonce (null pour utilisateur/avis, ou annonce
  // introuvable) — connue ici sans coût supplémentaire, évite de la
  // redéterminer par un aller-retour async côté composant.
  annonceTable: "logements" | "articles" | null;
  // Diagnostic par photo (clé = URL), vide si aucune analyse IA n'existe
  // pour cette annonce (signalement d'utilisateur pur, ou annonce publiée
  // avant l'introduction de ce suivi).
  diagnosticsPhotos: Record<string, PhotoDiagnostic>;
};

const LABEL_CATEGORIE: Record<string, string> = {
  pornographie: "Pornographie",
  violence: "Violence",
  stupefiants: "Stupéfiants",
};

export async function getAdminSignalements(): Promise<AdminSignalement[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("signalements")
    .select("id, statut, cible_type, cible_id, raison, description, date_signalement, signaleur:users!signaleur_id(nom)")
    .order("date_signalement", { ascending: false });

  if (error || !data) return [];

  const rows = data as unknown as {
    id: string;
    statut: string | null;
    cible_type: string | null;
    cible_id: string;
    raison: string | null;
    description: string | null;
    date_signalement: string;
    signaleur: { nom: string } | null;
  }[];

  // Un cible_id d'annonce peut être un logement ou un article : deux
  // requêtes groupées plutôt qu'un aller-retour par signalement.
  const idsAnnonces = rows
    .filter((s) => (s.cible_type ?? "annonce") === "annonce")
    .map((s) => s.cible_id);
  const photosParId = new Map<string, string[]>();
  const tableParId = new Map<string, "logements" | "articles">();
  if (idsAnnonces.length > 0) {
    const [{ data: logements }, { data: articles }] = await Promise.all([
      supabase.from("logements").select("id, photos").in("id", idsAnnonces),
      supabase.from("articles").select("id, photos").in("id", idsAnnonces),
    ]);
    for (const l of logements ?? []) {
      photosParId.set(l.id, l.photos ?? []);
      tableParId.set(l.id, "logements");
    }
    for (const a of articles ?? []) {
      photosParId.set(a.id, a.photos ?? []);
      tableParId.set(a.id, "articles");
    }
  }

  // Dernière analyse moderate-annonce par annonce (triée décroissant, on
  // ne garde que la première rencontrée par annonce_id) : construit le
  // diagnostic par photo à partir des colonnes photos_fraude/
  // photos_categories/photos_ignorees (voir
  // 20260801010000_moderation_ia_par_photo.sql).
  const diagnosticsParId = new Map<string, Record<string, PhotoDiagnostic>>();
  if (idsAnnonces.length > 0) {
    const { data: moderations } = await supabase
      .from("moderation_ia")
      .select("annonce_id, photos_fraude, photos_categories, photos_ignorees, created_at")
      .in("annonce_id", idsAnnonces)
      .order("created_at", { ascending: false });

    type ModerationRow = {
      annonce_id: string;
      photos_fraude: { url: string; matchUrl: string }[] | null;
      photos_categories: { url: string; pornographie?: boolean; violence?: boolean; stupefiants?: boolean }[] | null;
      photos_ignorees: { url: string; raison: string }[] | null;
      created_at: string;
    };

    for (const m of (moderations ?? []) as ModerationRow[]) {
      if (diagnosticsParId.has(m.annonce_id)) continue; // déjà la plus récente
      const diag: Record<string, PhotoDiagnostic> = {};
      const get = (url: string) =>
        (diag[url] ??= { fraude: false, matchUrl: null, categories: [], ignoree: false });
      for (const f of m.photos_fraude ?? []) {
        const d = get(f.url);
        d.fraude = true;
        d.matchUrl = f.matchUrl;
      }
      for (const c of m.photos_categories ?? []) {
        const d = get(c.url);
        for (const cle of ["pornographie", "violence", "stupefiants"] as const) {
          if (c[cle] === true) d.categories.push(LABEL_CATEGORIE[cle]);
        }
      }
      for (const ig of m.photos_ignorees ?? []) {
        get(ig.url).ignoree = true;
      }
      diagnosticsParId.set(m.annonce_id, diag);
    }
  }

  return rows.map((s) => ({
    id: s.id,
    statut: s.statut ?? "en-attente",
    cibleType: s.cible_type ?? "annonce",
    cibleId: s.cible_id,
    raison: s.raison ?? "",
    description: s.description,
    estDetectionIa: s.raison === "detection_ia",
    signaleurNom: s.signaleur?.nom ?? null,
    dateSignalement: s.date_signalement,
    photos: photosParId.get(s.cible_id) ?? [],
    annonceTable: tableParId.get(s.cible_id) ?? null,
    diagnosticsPhotos: diagnosticsParId.get(s.cible_id) ?? {},
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
  // Choisies par le candidat lui-même à l'inscription (voir
  // register/vendeur/page.tsx) : pré-remplissent le dialogue de
  // validation admin (create-vendor-dialog.tsx) au lieu de partir vide.
  ville: string | null;
  sousRolesDemandees: string[];
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
    ville: d.ville ?? null,
    sousRolesDemandees: d.sous_roles_demandees ?? [],
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
  // est_ambassadeur est un privilège superposé (voir HISTORIQUE_PROJET_MBOA.md
  // §4.9) : un ambassadeur nommé garde son rôle de base, role="ambassadeur"
  // seul ne suffit donc pas à le trouver.
  const { data } = await supabase
    .from("users")
    .select("id, nom")
    .or("role.eq.ambassadeur,est_ambassadeur.eq.true");
  return (data ?? []).map((a) => ({ id: a.id, nom: a.nom ?? "" }));
}
