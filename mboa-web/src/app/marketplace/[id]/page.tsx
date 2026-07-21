import type { Metadata } from "next";
import { notFound } from "next/navigation";
import Link from "next/link";
import { getArticle } from "@/lib/data/articles";
import { getCurrentUser } from "@/lib/data/auth";
import { getIsFavori } from "@/lib/data/favoris";
import { getAvisAnnonce } from "@/lib/data/avis";
import { formatPrix, formatRelativeDate, initiales } from "@/lib/utils/format";
import { GalleryHero } from "@/components/logement/gallery-hero";
import { BackButton } from "@/components/ui/back-button";
import { FavoriButton } from "@/components/ui/favori-button";
import { LaisserAvisButton } from "@/components/ui/laisser-avis-button";
import { SignalerButton } from "@/components/ui/signaler-button";
import { ContactSticky } from "@/components/logement/contact-sticky";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ id: string }>;
}): Promise<Metadata> {
  const { id } = await params;
  const article = await getArticle(id);
  if (!article) return { title: "Article introuvable" };
  return {
    title: `${article.titre} — ${formatPrix(article.prix)}`,
    description: article.description.slice(0, 160),
  };
}

const ETAT_COLORS: Record<string, string> = {
  Neuf: "var(--color-mboa-verified)",
  "Très bon état": "var(--color-mboa-primary)",
  "Bon état": "var(--color-mboa-primary-light)",
};

function localisation(article: { lat: number | null; lng: number | null }) {
  if (article.lat != null && article.lng != null) {
    return `${article.lat.toFixed(4)}, ${article.lng.toFixed(4)}`;
  }
  return "Localisation inconnue";
}

export default async function ArticleDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const [article, user, avis] = await Promise.all([
    getArticle(id),
    getCurrentUser(),
    getAvisAnnonce(id),
  ]);

  if (!article) notFound();

  const isFavori = user ? await getIsFavori(user.id, "article", id) : false;
  const etatColor = ETAT_COLORS[article.etat] ?? "var(--color-mboa-text-muted)";

  return (
    <div>
      <div className="relative">
        <GalleryHero photos={article.photos} alt={article.titre} boosted={article.boosted} />
        <div className="absolute left-4 top-4">
          <BackButton />
        </div>
        <div className="absolute right-4 top-4">
          <FavoriButton
            annonceId={article.id}
            type="article"
            initialFavori={isFavori}
            isLoggedIn={!!user}
          />
        </div>
      </div>

      <div className="mx-auto max-w-3xl px-5 py-6 sm:px-6">
        <div className="flex items-start justify-between gap-3">
          <h1 className="text-xl font-extrabold leading-snug text-mboa-text sm:text-2xl">
            {article.titre}
          </h1>
          <span
            className="shrink-0 rounded-mboa-full border px-2.5 py-1 text-[11px] font-bold"
            style={{
              color: etatColor,
              borderColor: `color-mix(in srgb, ${etatColor} 30%, transparent)`,
              backgroundColor: `color-mix(in srgb, ${etatColor} 12%, transparent)`,
            }}
          >
            {article.etat}
          </span>
        </div>

        <div className="mt-2 flex flex-wrap items-center gap-2">
          <span className="rounded-mboa-full bg-mboa-secondary/12 px-2.5 py-1 text-[11px] font-semibold text-mboa-secondary">
            {article.categorie}
          </span>
          {article.negociable && (
            <span className="rounded-mboa-full bg-mboa-primary/8 px-2.5 py-1 text-[11px] font-semibold text-mboa-primary">
              💬 Prix négociable
            </span>
          )}
        </div>

        <div className="mt-4 flex items-center justify-between rounded-mboa-lg bg-gradient-to-r from-mboa-accent to-mboa-secondary p-4">
          <div>
            <p className="text-xs text-white/70">Prix de vente</p>
            <p className="mt-1 text-2xl font-extrabold text-white">
              {formatPrix(article.prix)}
            </p>
          </div>
          {article.negociable && (
            <span className="rounded-mboa-full bg-white/20 px-3.5 py-2 text-xs font-bold text-white">
              Négociable
            </span>
          )}
        </div>

        <div className="mt-7">
          <h2 className="text-base font-bold text-mboa-text">Description</h2>
          <div className="mt-2.5 rounded-mboa-md bg-mboa-card p-3.5 shadow-sm">
            <p className="whitespace-pre-line text-sm leading-relaxed text-mboa-text">
              {article.description || "Aucune description disponible."}
            </p>
          </div>
        </div>

        <div className="mt-7">
          <h2 className="text-base font-bold text-mboa-text">👤 Vendeur</h2>
          <Link
            href={`/vendeur/${article.vendeurId}`}
            className="mt-3 flex items-center gap-3.5 rounded-mboa-lg border border-mboa-border bg-mboa-card p-4 shadow-sm"
          >
            <span className="flex h-13 w-13 shrink-0 items-center justify-center rounded-full bg-mboa-secondary text-lg font-bold text-white">
              {initiales(article.vendeurNom ?? "V")}
            </span>
            <div className="flex-1">
              <p className="text-sm font-bold text-mboa-text">
                {article.vendeurNom ?? "Vendeur"}
              </p>
              <p className="text-xs text-mboa-text-muted">
                ⭐ {article.vendeurNote.toFixed(1)}
                <span className="text-mboa-primary"> · Voir le profil →</span>
              </p>
            </div>
          </Link>
        </div>

        <div className="mt-7">
          <h2 className="text-base font-bold text-mboa-text">ℹ️ Informations</h2>
          <div className="mt-2.5 divide-y divide-mboa-border rounded-mboa-lg bg-mboa-card shadow-sm">
            {[
              ["📦", "Catégorie", article.categorie],
              ["🏷️", "État", article.etat],
              ["📍", "Localisation", localisation(article)],
              ["📅", "Publié", formatRelativeDate(article.datePublication)],
            ].map(([icon, label, value]) => (
              <div key={label} className="flex items-center justify-between px-4 py-3 text-sm">
                <span className="text-mboa-text-muted">
                  {icon} {label}
                </span>
                <span className="font-semibold text-mboa-text">{value}</span>
              </div>
            ))}
          </div>
        </div>

        {article.accepteAvis && (
          <div className="mt-7">
            <div className="flex items-center justify-between">
              <h2 className="text-base font-bold text-mboa-text">⭐ Avis ({avis.length})</h2>
              <LaisserAvisButton
                cibleId={article.vendeurId}
                annonceId={article.id}
                isLoggedIn={!!user}
              />
            </div>
            {avis.length === 0 ? (
              <div className="mt-3 rounded-mboa-md bg-mboa-card p-4 text-center text-sm text-mboa-text-muted">
                Aucun avis pour le moment
              </div>
            ) : (
              <div className="mt-3 space-y-2.5">
                {avis.map((a) => (
                  <div key={a.id} className="rounded-mboa-md bg-mboa-card p-3.5 shadow-sm">
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-bold text-mboa-text">{a.auteurNom}</p>
                      <span className="text-xs text-mboa-boost">
                        {"★".repeat(a.note)}
                        {"☆".repeat(5 - a.note)}
                      </span>
                    </div>
                    {a.commentaire && (
                      <p className="mt-2 text-sm leading-relaxed text-mboa-text">
                        {a.commentaire}
                      </p>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        <div className="mt-6">
          <SignalerButton annonceId={article.id} />
        </div>

        <p className="mt-6 text-center text-xs text-mboa-text-muted">
          👁 {article.vues} vues
        </p>
      </div>

      <ContactSticky
        destinataireId={article.vendeurId}
        annonceId={article.id}
        annonceType="article"
        annonceTitre={article.titre}
        isLoggedIn={!!user}
      />
    </div>
  );
}
