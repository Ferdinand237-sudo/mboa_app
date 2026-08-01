import { createClient } from "@/lib/supabase/server";

// Les policies UPDATE de logements/articles sont restreintes au
// propriétaire/vendeur ou à un admin : un visiteur ne peut pas faire
// d'update({vues: ...}) direct. incrementerVues() appelle une fonction
// Postgres security definer dédiée à ce seul incrément atomique.
// À appeler une seule fois par page vue réelle (dans le composant de
// page, pas dans generateMetadata ni dans un getLogement/getArticle
// partagé qui serait aussi invoqué par generateMetadata).
export async function incrementerVues(
  type: "logement" | "article",
  id: string
) {
  const supabase = await createClient();
  const fn =
    type === "logement" ? "increment_vues_logement" : "increment_vues_article";
  try {
    await supabase.rpc(fn, { p_id: id });
  } catch {
    // best-effort : ne doit jamais faire échouer l'affichage de la page
  }
}
