import Link from "next/link";
import { getLogements } from "@/lib/data/logements";
import { getArticles } from "@/lib/data/articles";
import { LogementCard } from "@/components/logement/logement-card";
import { ArticleCard } from "@/components/market/article-card";

export default async function HomePage() {
  const [logements, articles] = await Promise.all([
    getLogements({ limit: 4 }),
    getArticles({ limit: 4 }),
  ]);

  return (
    <div>
      <section className="bg-gradient-to-br from-mboa-primary-dark via-mboa-primary to-mboa-primary-light">
        <div className="mx-auto max-w-6xl px-4 py-16 sm:px-6 sm:py-24">
          <h1 className="max-w-2xl text-3xl font-extrabold leading-tight text-white sm:text-5xl">
            Ton premier ami dans une nouvelle ville
          </h1>
          <p className="mt-4 max-w-xl text-base text-white/90 sm:text-lg">
            Trouve un logement à Sangmelima avant même d&apos;arriver, et
            équipe-toi grâce au marketplace étudiant Mboa.
          </p>

          <form
            action="/logements"
            className="mt-8 flex max-w-xl overflow-hidden rounded-mboa-lg bg-white shadow-lg"
          >
            <input
              type="text"
              name="search"
              placeholder="Chambre, studio, quartier..."
              className="w-full px-5 py-4 text-sm text-mboa-text outline-none placeholder:text-mboa-text-muted"
            />
            <button
              type="submit"
              className="shrink-0 bg-mboa-secondary px-6 text-sm font-bold text-mboa-text"
            >
              Rechercher
            </button>
          </form>

          <div className="mt-6 flex flex-wrap gap-3">
            <Link
              href="/logements"
              className="rounded-mboa-full bg-white/15 px-4 py-2 text-sm font-semibold text-white backdrop-blur hover:bg-white/25"
            >
              🏠 Logement
            </Link>
            <Link
              href="/marketplace"
              className="rounded-mboa-full bg-white/15 px-4 py-2 text-sm font-semibold text-white backdrop-blur hover:bg-white/25"
            >
              🛍 Market
            </Link>
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-4 py-12 sm:px-6">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold text-mboa-text sm:text-2xl">
            Logements récents
          </h2>
          <Link
            href="/logements"
            className="text-sm font-semibold text-mboa-primary hover:underline"
          >
            Voir tout →
          </Link>
        </div>
        {logements.length === 0 ? (
          <p className="mt-6 text-sm text-mboa-text-muted">
            Aucun logement disponible pour le moment.
          </p>
        ) : (
          <div className="mt-6 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
            {logements.map((logement) => (
              <LogementCard key={logement.id} logement={logement} />
            ))}
          </div>
        )}
      </section>

      <section className="mx-auto max-w-6xl px-4 pb-16 sm:px-6">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold text-mboa-text sm:text-2xl">
            Articles Market
          </h2>
          <Link
            href="/marketplace"
            className="text-sm font-semibold text-mboa-primary hover:underline"
          >
            Voir tout →
          </Link>
        </div>
        {articles.length === 0 ? (
          <p className="mt-6 text-sm text-mboa-text-muted">
            Aucun article disponible pour le moment.
          </p>
        ) : (
          <div className="mt-6 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
            {articles.map((article) => (
              <ArticleCard key={article.id} article={article} />
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
