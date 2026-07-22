import { createClient } from "@/lib/supabase/server";

export async function getIsFavori(
  userId: string,
  type: "logement" | "article",
  annonceId: string,
): Promise<boolean> {
  const supabase = await createClient();
  const column = type === "logement" ? "logement_id" : "article_id";

  const { data } = await supabase
    .from("favoris")
    .select("id")
    .eq("user_id", userId)
    .eq(column, annonceId)
    .maybeSingle();

  return data != null;
}
