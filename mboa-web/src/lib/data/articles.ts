import { createClient } from "@/lib/supabase/server";
import { articleFromRow, type ArticleModel } from "@/lib/types/models";
import { PAGE_SIZE } from "@/lib/constants";

const SELECT_WITH_VENDEUR =
  "*, vendeur:users!vendeur_id(nom, photo_url, verified, note_globale)";

export async function getArticles(params: {
  categorie?: string;
  etat?: string;
  search?: string;
  limit?: number;
  offset?: number;
}): Promise<ArticleModel[]> {
  const { categorie, etat, search, limit = PAGE_SIZE, offset = 0 } = params;
  const supabase = await createClient();

  let query = supabase
    .from("articles")
    .select(SELECT_WITH_VENDEUR)
    .eq("statut", "disponible")
    .eq("statut_moderation", "publie");

  if (categorie && categorie !== "Tous") {
    query = query.eq("categorie", categorie);
  }
  if (etat && etat !== "Tous") {
    query = query.eq("etat", etat);
  }
  if (search) {
    query = query.or(`titre.ilike.%${search}%,description.ilike.%${search}%`);
  }

  const { data, error } = await query
    .order("boosted", { ascending: false })
    .order("date_publication", { ascending: false })
    .range(offset, offset + limit - 1);

  if (error) {
    console.error("getArticles", error.message);
    return [];
  }

  return (data ?? []).map(articleFromRow);
}

export async function getArticle(id: string): Promise<ArticleModel | null> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from("articles")
    .select(SELECT_WITH_VENDEUR)
    .eq("id", id)
    .eq("statut_moderation", "publie")
    .single();

  if (error || !data) return null;

  return articleFromRow(data);
}
