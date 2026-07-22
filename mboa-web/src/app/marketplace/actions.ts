"use server";

import { getArticles } from "@/lib/data/articles";
import { createClient } from "@/lib/supabase/server";
import type { ArticleModel } from "@/lib/types/models";

export async function searchArticles(filters: {
  categorie?: string;
  etat?: string;
  search?: string;
}): Promise<ArticleModel[]> {
  return getArticles({ ...filters, limit: 200 });
}

export async function enregistrerAlerteArticle(libelle: string, criteres: Record<string, unknown>) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return { error: "not-logged-in" as const };

  const { error } = await supabase.from("alertes_recherche").insert({
    user_id: user.id,
    type: "article",
    libelle,
    criteres,
  });

  return { error: error ? error.message : null };
}
