import { createClient } from "@/lib/supabase/server";
import { logementFromRow, type LogementModel } from "@/lib/types/models";
import { PAGE_SIZE } from "@/lib/constants";

const SELECT_WITH_PROPRIETAIRE =
  "*, proprietaire:users!proprietaire_id(nom, photo_url, verified, note_globale, nb_avis)";

export async function getLogements(params: {
  type?: string;
  prixMax?: number;
  search?: string;
  limit?: number;
  offset?: number;
}): Promise<LogementModel[]> {
  const { type, prixMax, search, limit = PAGE_SIZE, offset = 0 } = params;
  const supabase = await createClient();

  let query = supabase
    .from("logements")
    .select(SELECT_WITH_PROPRIETAIRE)
    .eq("statut", "disponible")
    .eq("statut_moderation", "publie");

  if (type && type !== "Tous") {
    query = query.eq("type", type);
  }
  if (prixMax != null) {
    query = query.lte("prix", prixMax);
  }
  if (search) {
    query = query.or(
      `titre.ilike.%${search}%,quartier.ilike.%${search}%,description.ilike.%${search}%`,
    );
  }

  const { data, error } = await query
    .order("boosted", { ascending: false })
    .order("note_globale", { ascending: false })
    .order("date_publication", { ascending: false })
    .range(offset, offset + limit - 1);

  if (error) {
    console.error("getLogements", error.message);
    return [];
  }

  return (data ?? []).map(logementFromRow);
}

export async function getLogement(id: string): Promise<LogementModel | null> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from("logements")
    .select(SELECT_WITH_PROPRIETAIRE)
    .eq("id", id)
    .eq("statut_moderation", "publie")
    .single();

  if (error || !data) return null;

  return logementFromRow(data);
}
