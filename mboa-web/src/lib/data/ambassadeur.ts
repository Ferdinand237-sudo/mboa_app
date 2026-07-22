import { createClient } from "@/lib/supabase/server";

// Miroir de _charger (ambassadeur_dashboard_screen.dart).
export type AmbassadeurStats = {
  nom: string;
  nbAssignes: number;
  nbEnAttenteAdmin: number;
  nbValidees: number;
  nbRejetees: number;
};

export async function getAmbassadeurStats(userId: string): Promise<AmbassadeurStats> {
  const supabase = await createClient();
  const [profilRes, verifsRes] = await Promise.all([
    supabase.from("users").select("nom").eq("id", userId).single(),
    supabase.from("verifications_terrain").select("statut").eq("ambassadeur_id", userId),
  ]);

  const statuts = (verifsRes.data ?? []).map((v) => v.statut as string);
  return {
    nom: profilRes.data?.nom ?? "",
    nbAssignes: statuts.filter((s) => s === "assignee").length,
    nbEnAttenteAdmin: statuts.filter((s) => s === "visite_effectuee").length,
    nbValidees: statuts.filter((s) => s === "validee").length,
    nbRejetees: statuts.filter((s) => s === "rejetee").length,
  };
}

// Miroir de _charger (ambassadeur_liste_screen.dart).
export type AssignationItem = {
  id: string;
  statut: string;
  proprietaireNom: string;
  proprietaireContact: string;
};

export async function getMesAssignations(userId: string): Promise<AssignationItem[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("verifications_terrain")
    .select("id, statut, proprietaire:users!verifications_terrain_user_id_fkey(nom, telephone, email)")
    .eq("ambassadeur_id", userId)
    .order("created_at", { ascending: false });

  if (error || !data) return [];

  return (data as unknown as {
    id: string;
    statut: string | null;
    proprietaire: { nom: string; telephone: string | null; email: string } | null;
  }[]).map((v) => ({
    id: v.id,
    statut: v.statut ?? "",
    proprietaireNom: v.proprietaire?.nom ?? "Propriétaire",
    proprietaireContact: v.proprietaire?.telephone ?? v.proprietaire?.email ?? "",
  }));
}

// Miroir des données passées à AmbassadeurVisiteScreen.
export type VisiteDetail = {
  id: string;
  statut: string;
  proprietaireNom: string;
  conformiteBien: boolean | null;
  typeJustificatif: string | null;
  notes: string | null;
  dateVisite: string | null;
  aUneAttestation: boolean;
};

export async function getVisiteDetail(id: string, ambassadeurId: string): Promise<VisiteDetail | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("verifications_terrain")
    .select(
      "id, statut, conformite_bien, type_justificatif, notes, date_visite, attestation_path, ambassadeur_id, proprietaire:users!verifications_terrain_user_id_fkey(nom)",
    )
    .eq("id", id)
    .single();

  if (error || !data || data.ambassadeur_id !== ambassadeurId) return null;

  const proprietaire = data.proprietaire as unknown as { nom: string } | null;
  return {
    id: data.id,
    statut: data.statut ?? "",
    proprietaireNom: proprietaire?.nom ?? "Propriétaire",
    conformiteBien: data.conformite_bien,
    typeJustificatif: data.type_justificatif,
    notes: data.notes,
    dateVisite: data.date_visite,
    aUneAttestation: !!data.attestation_path,
  };
}
