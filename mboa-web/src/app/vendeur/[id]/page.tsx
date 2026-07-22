import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getVendeurProfil } from "@/lib/data/vendeur";
import { getAvisUtilisateur } from "@/lib/data/avis";
import { getCurrentUser } from "@/lib/data/auth";
import { initiales, formatDateFr } from "@/lib/utils/format";
import { Badge } from "@/components/ui/badge";
import { LogementCard } from "@/components/logement/logement-card";
import { ArticleCard } from "@/components/market/article-card";
import { ContactButtons } from "@/components/vendeur/contact-buttons";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ id: string }>;
}): Promise<Metadata> {
  const { id } = await params;
  const profil = await getVendeurProfil(id);
  if (!profil) return { title: "Profil introuvable" };
  return { title: profil.user.nomCommerce ?? profil.user.nom };
}

export default async function VendeurPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const [profil, avis, currentUser] = await Promise.all([
    getVendeurProfil(id),
    getAvisUtilisateur(id),
    getCurrentUser(),
  ]);

  if (!profil) notFound();

  const { user, logements, articles } = profil;

  return (
    <div>
      <div className="bg-gradient-to-br from-mboa-primary-dark via-mboa-primary to-mboa-primary-light">
        <div className="mx-auto flex max-w-4xl flex-col items-center px-4 py-12 text-center sm:px-6">
          <span className="flex h-24 w-24 items-center justify-center rounded-full bg-white/15 text-3xl font-extrabold text-white ring-4 ring-white/20">
            {initiales(user.nom)}
          </span>
          <h1 className="mt-4 flex items-center gap-1.5 text-xl font-extrabold text-white">
            {user.nomCommerce ?? user.nom}
            {user.verified && <span title="Vérifié">✓</span>}
          </h1>
          {user.nomCommerce && (
            <p className="text-sm text-white/80">{user.nom}</p>
          )}
          {user.descriptionCommerce && (
            <p className="mt-2 max-w-md text-sm text-white/90">
              {user.descriptionCommerce}
            </p>
          )}
          <div className="mt-3 flex flex-wrap items-center justify-center gap-2">
            <Badge variant="neutral">
              ⭐ {user.noteGlobale.toFixed(1)} ({user.nbAvis} avis)
            </Badge>
            <Badge variant="neutral">
              Depuis {new Date(user.dateInscription).getFullYear()}
            </Badge>
          </div>

          <div className="mt-6 w-full max-w-xs">
            <ContactButtons
              vendeurId={user.id}
              isLoggedIn={!!currentUser}
              isSelf={currentUser?.id === user.id}
            />
          </div>
        </div>
      </div>

      <div className="mx-auto max-w-4xl px-4 py-8 sm:px-6">
        {logements.length > 0 && (
          <div className="mb-10">
            <h2 className="text-lg font-bold text-mboa-text">
              🏘 Logements ({logements.length})
            </h2>
            <div className="mt-4 grid grid-cols-2 gap-4 sm:grid-cols-3">
              {logements.map((l) => (
                <LogementCard key={l.id} logement={l} />
              ))}
            </div>
          </div>
        )}

        {articles.length > 0 && (
          <div className="mb-10">
            <h2 className="text-lg font-bold text-mboa-text">
              🛒 Articles ({articles.length})
            </h2>
            <div className="mt-4 grid grid-cols-2 gap-4 sm:grid-cols-3">
              {articles.map((a) => (
                <ArticleCard key={a.id} article={a} />
              ))}
            </div>
          </div>
        )}

        {logements.length === 0 && articles.length === 0 && (
          <p className="text-center text-sm text-mboa-text-muted">
            Aucune annonce active pour le moment.
          </p>
        )}

        <div className="mt-10">
          <h2 className="text-lg font-bold text-mboa-text">
            ⭐ Avis ({avis.length})
          </h2>
          {avis.length === 0 ? (
            <p className="mt-3 text-sm text-mboa-text-muted">
              Aucun avis pour l&apos;instant.
            </p>
          ) : (
            <div className="mt-4 space-y-3">
              {avis.map((a) => (
                <div
                  key={a.id}
                  className="rounded-mboa-md border border-mboa-border bg-mboa-card p-4"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2.5">
                      <span className="flex h-8 w-8 items-center justify-center rounded-full bg-mboa-primary/20 text-xs font-bold text-mboa-primary">
                        {initiales(a.auteurNom)}
                      </span>
                      <div>
                        <p className="text-sm font-bold text-mboa-text">
                          {a.auteurNom}
                        </p>
                        <p className="text-[11px] text-mboa-text-muted">
                          {formatDateFr(a.datePublication)}
                        </p>
                      </div>
                    </div>
                    <span className="text-xs text-mboa-boost">
                      {"★".repeat(a.note)}
                      {"☆".repeat(5 - a.note)}
                    </span>
                  </div>
                  {a.commentaire && (
                    <p className="mt-2.5 text-sm leading-relaxed text-mboa-text">
                      {a.commentaire}
                    </p>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
