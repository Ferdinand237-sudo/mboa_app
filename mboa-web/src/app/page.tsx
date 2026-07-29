import { getHomeLogements, getHomeArticles, getContributeurs, getLieuxPublics } from "@/lib/data/home";
import { getCurrentUser } from "@/lib/data/auth";
import { getVilles, getVilleActuelle } from "@/lib/data/villes";
import { HeroHeader } from "@/components/home/hero-header";
import { CategoryCards } from "@/components/home/category-cards";
import { SectionTitle } from "@/components/home/section-title";
import { HomeLogementCard } from "@/components/home/home-logement-card";
import { HomeArticleCard } from "@/components/home/home-article-card";
import { ContributeurCard } from "@/components/home/contributeur-card";
import { TrouveTonMboa } from "@/components/home/trouve-ton-mboa";
import { TrouveTonMboaLocked } from "@/components/home/trouve-ton-mboa-locked";
import { TOUR_HOME_VISITEUR, TOUR_HOME_ETUDIANT, TOUR_HOME_VENDEUR } from "@/components/onboarding/tours";

const SEEN_KEY_HOME_VISITEUR = "mboa_tour_seen";

export default async function HomePage() {
  const [user, villes, { ville: villeActuelle, cookiePresent }] = await Promise.all([
    getCurrentUser(),
    getVilles(),
    getVilleActuelle(),
  ]);

  const [logements, articles, contributeurs, lieuxPublics] = await Promise.all([
    getHomeLogements(villeActuelle.nom),
    getHomeArticles(villeActuelle.nom),
    getContributeurs(),
    getLieuxPublics(villeActuelle.nom),
  ]);

  const prenom = user ? user.nom.split(" ")[0] : "Visiteur";

  // Visiteur non connecté : visite guidée générale + lancement automatique
  // (une fois) pour accueillir les tout nouveaux arrivants. Étudiant connecté
  // et vendeur : même bouton dans le hero, mais uniquement au clic — ce ne
  // sont pas de nouveaux venus sur le site.
  const tourSteps = !user
    ? TOUR_HOME_VISITEUR
    : user.role === "vendeur"
      ? TOUR_HOME_VENDEUR
      : TOUR_HOME_ETUDIANT;
  const tourAutoOpenKey = !user ? SEEN_KEY_HOME_VISITEUR : undefined;

  return (
    <div>
      <HeroHeader
        prenom={prenom}
        tourSteps={tourSteps}
        tourAutoOpenKey={tourAutoOpenKey}
        villes={villes}
        villeActuelle={villeActuelle}
        cookiePresent={cookiePresent}
      />

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
            <TrouveTonMboa key={villeActuelle.nom} lieuxPublics={lieuxPublics} villeActuelle={villeActuelle} />
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
