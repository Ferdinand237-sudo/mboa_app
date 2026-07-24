import { getHomeLogements, getHomeArticles, getContributeurs, getLieuxPublics } from "@/lib/data/home";
import { getCurrentUser } from "@/lib/data/auth";
import { HeroHeader } from "@/components/home/hero-header";
import { CategoryCards } from "@/components/home/category-cards";
import { SectionTitle } from "@/components/home/section-title";
import { HomeLogementCard } from "@/components/home/home-logement-card";
import { HomeArticleCard } from "@/components/home/home-article-card";
import { ContributeurCard } from "@/components/home/contributeur-card";
import { TrouveTonMboa } from "@/components/home/trouve-ton-mboa";
import { TrouveTonMboaLocked } from "@/components/home/trouve-ton-mboa-locked";

export default async function HomePage() {
  const user = await getCurrentUser();

  const [logements, articles, contributeurs, lieuxPublics] = await Promise.all([
    getHomeLogements(),
    getHomeArticles(),
    getContributeurs(),
    getLieuxPublics(),
  ]);

  const prenom = user ? user.nom.split(" ")[0] : "Visiteur";

  return (
    <div>
      <HeroHeader prenom={prenom} />

      <div className="mx-auto max-w-7xl px-5 py-6 sm:px-6">
        {/* Explorer */}
        <SectionTitle title="Explorer" />
        <div className="mt-3.5">
          <CategoryCards />
        </div>

        {/* Logements récents */}
        <div className="mt-7">
          <SectionTitle
            title="🏘 Logements récents"
            actionLabel="Voir tout"
            actionHref="/logements"
          />
          <div className="mt-3.5">
            {logements.length === 0 ? (
              <div className="rounded-mboa-lg bg-mboa-card p-6 text-center text-sm text-mboa-text-muted">
                Aucun logement disponible
              </div>
            ) : (
              <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6">
                {logements.map((l) => (
                  <HomeLogementCard key={l.id} logement={l} />
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Trouve ton Mboa */}
        <div className="mt-7">
          {user ? (
            <TrouveTonMboa lieuxPublics={lieuxPublics} />
          ) : (
            <TrouveTonMboaLocked />
          )}
        </div>

        {/* Bons plans Market */}
        <div className="mt-7">
          <SectionTitle
            title="🛒 Bons plans Market"
            actionLabel="Voir tout"
            actionHref="/marketplace"
          />
          <div className="mt-3.5">
            {articles.length === 0 ? (
              <div className="rounded-mboa-lg bg-mboa-card p-6 text-center text-sm text-mboa-text-muted">
                Aucun article disponible
              </div>
            ) : (
              <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6">
                {articles.map((a) => (
                  <HomeArticleCard key={a.id} article={a} />
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Contributeurs */}
        <div className="mt-7">
          <SectionTitle
            title="🤝 Contributeurs Mboa"
            actionLabel="Voir tout"
            actionHref="/contributeurs"
          />
          <div className="mt-3.5">
            {contributeurs.length === 0 ? (
              <div className="rounded-mboa-lg bg-mboa-card p-6 text-center text-sm text-mboa-text-muted">
                Aucun contributeur pour le moment
              </div>
            ) : (
              <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6">
                {contributeurs.map((c) => (
                  <ContributeurCard key={c.id} contributeur={c} />
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
