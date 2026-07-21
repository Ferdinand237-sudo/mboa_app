import type { Metadata } from "next";
import { getArticles } from "@/lib/data/articles";
import { getCurrentUser } from "@/lib/data/auth";
import { ArticleCard } from "@/components/market/article-card";
import { VisitorGate } from "@/components/ui/visitor-gate";
import { CATEGORIES_MARKET, ETATS_ARTICLE, PAGE_SIZE, PAGE_SIZE_VISITEUR } from "@/lib/constants";

export const metadata: Metadata = {
  title: "Marketplace étudiant",
  description:
    "Achète et vends des équipements entre étudiants à Sangmelima : literie, mobilier, électronique, fournitures scolaires.",
};

export default async function MarketplacePage({
  searchParams,
}: {
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}) {
  const params = await searchParams;
  const search = typeof params.search === "string" ? params.search : undefined;
  const categorie = typeof params.categorie === "string" ? params.categorie : undefined;
  const etat = typeof params.etat === "string" ? params.etat : undefined;

  const user = await getCurrentUser();
  const limit = user ? PAGE_SIZE : PAGE_SIZE_VISITEUR;

  const articles = await getArticles({ categorie, etat, search, limit });

  return (
    <div className="mx-auto max-w-6xl px-4 py-8 sm:px-6">
      <h1 className="text-2xl font-extrabold text-mboa-text sm:text-3xl">
        Marketplace étudiant
      </h1>
      <p className="mt-1 text-sm text-mboa-text-muted">
        Achète et vends des équipements entre étudiants à Sangmelima.
      </p>

      <form className="mt-6 flex flex-wrap gap-3 rounded-mboa-lg border border-mboa-border bg-mboa-card p-4">
        <input
          type="text"
          name="search"
          defaultValue={search}
          placeholder="Titre, description..."
          className="min-w-[200px] flex-1 rounded-mboa-md border border-mboa-border bg-mboa-background px-4 py-2.5 text-sm outline-none focus:border-mboa-primary"
        />
        <select
          name="categorie"
          defaultValue={categorie ?? ""}
          className="rounded-mboa-md border border-mboa-border bg-mboa-background px-4 py-2.5 text-sm outline-none focus:border-mboa-primary"
        >
          <option value="">Toutes catégories</option>
          {CATEGORIES_MARKET.map((c) => (
            <option key={c.label} value={c.label}>
              {c.icon} {c.label}
            </option>
          ))}
        </select>
        <select
          name="etat"
          defaultValue={etat ?? ""}
          className="rounded-mboa-md border border-mboa-border bg-mboa-background px-4 py-2.5 text-sm outline-none focus:border-mboa-primary"
        >
          <option value="">Tous états</option>
          {ETATS_ARTICLE.map((e) => (
            <option key={e} value={e}>
              {e}
            </option>
          ))}
        </select>
        <button
          type="submit"
          className="rounded-mboa-md bg-mboa-primary px-6 py-2.5 text-sm font-bold text-white"
        >
          Filtrer
        </button>
      </form>

      {articles.length === 0 ? (
        <div className="mt-10 rounded-mboa-lg border border-mboa-border bg-mboa-card p-10 text-center text-sm text-mboa-text-muted">
          Aucun article ne correspond à ta recherche pour le moment.
        </div>
      ) : (
        <div className="mt-8 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
          {articles.map((article) => (
            <ArticleCard key={article.id} article={article} />
          ))}
          {!user && articles.length >= PAGE_SIZE_VISITEUR && <VisitorGate />}
        </div>
      )}
    </div>
  );
}
