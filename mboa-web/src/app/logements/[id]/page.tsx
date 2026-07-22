import type { Metadata } from "next";
import { notFound } from "next/navigation";
import Link from "next/link";
import { getLogement } from "@/lib/data/logements";
import { getCurrentUser } from "@/lib/data/auth";
import { getIsFavori } from "@/lib/data/favoris";
import { getAvisAnnonce } from "@/lib/data/avis";
import { getLieuxPublics } from "@/lib/data/home";
import { formatPrix, formatDateFr, initiales } from "@/lib/utils/format";
import { distanceMetres, formatDistance } from "@/lib/utils/geo";
import { CATEGORIE_STYLE_PROXIMITE } from "@/lib/constants";
import { Badge } from "@/components/ui/badge";
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
  const logement = await getLogement(id);
  if (!logement) return { title: "Logement introuvable" };
  return {
    title: `${logement.titre} — ${formatPrix(logement.prix)}`,
    description: logement.description.slice(0, 160),
  };
}

export default async function LogementDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const [logement, user, avis, lieuxPublics] = await Promise.all([
    getLogement(id),
    getCurrentUser(),
    getAvisAnnonce(id),
    getLieuxPublics(),
  ]);

  if (!logement) notFound();

  const isFavori = user ? await getIsFavori(user.id, "logement", id) : false;

  const proximite =
    logement.lat != null && logement.lng != null
      ? lieuxPublics
          .map((lieu) => {
            const style = CATEGORIE_STYLE_PROXIMITE[lieu.categorie] ?? CATEGORIE_STYLE_PROXIMITE.autre;
            return {
              ...lieu,
              distanceM: distanceMetres(logement.lat!, logement.lng!, lieu.lat, lieu.lng),
              icon: style.icon,
              color: style.color,
            };
          })
          .sort((a, b) => a.distanceM - b.distanceM)
          .slice(0, 6)
      : [];

  return (
    <div className="pb-0">
      <div className="relative">
        <GalleryHero photos={logement.photos} alt={logement.titre} boosted={logement.boosted} />
        <div className="absolute left-4 top-4">
          <BackButton />
        </div>
        <div className="absolute right-4 top-4">
          <FavoriButton
            annonceId={logement.id}
            type="logement"
            initialFavori={isFavori}
            isLoggedIn={!!user}
          />
        </div>
      </div>

      <div className="mx-auto max-w-3xl px-5 py-6 sm:px-6">
        <div className="flex items-start justify-between gap-3">
          <h1 className="text-xl font-extrabold leading-snug text-mboa-text sm:text-2xl">
            {logement.titre}
          </h1>
          {logement.proprietaireVerified && <Badge variant="verified">✅ Vérifié</Badge>}
        </div>
        <p className="mt-1.5 text-sm text-mboa-text-muted">
          📍 {logement.quartier ?? ""} · {logement.ville}
        </p>

        <div className="mt-4 flex items-start justify-between">
          <div>
            <p className="text-2xl font-extrabold text-mboa-primary">
              {formatPrix(logement.prix)}
            </p>
            <p className="text-xs text-mboa-text-muted">par mois</p>
          </div>
          <div className="text-right">
            <div className="flex items-center gap-1.5 text-mboa-text">
              <span className="text-lg text-mboa-boost">⭐</span>
              <span className="text-lg font-extrabold">
                {logement.proprietaireNoteGlobale.toFixed(1)}
              </span>
              <span className="text-sm text-mboa-text-muted">
                ({logement.proprietaireNbAvis} avis)
              </span>
            </div>
            <p className="text-[10px] text-mboa-text-muted">Note globale du vendeur</p>
          </div>
        </div>

        <div className="mt-4 flex flex-wrap gap-2.5">
          <span className="rounded-mboa-full border border-mboa-border bg-mboa-card px-3 py-1.5 text-xs font-semibold text-mboa-text shadow-sm">
            📐 {logement.surface ?? "?"}m²
          </span>
          <span className="rounded-mboa-full border border-mboa-border bg-mboa-card px-3 py-1.5 text-xs font-semibold text-mboa-text shadow-sm">
            🏠 {logement.type}
          </span>
          <span className="rounded-mboa-full border border-mboa-border bg-mboa-card px-3 py-1.5 text-xs font-semibold text-mboa-text shadow-sm">
            ✅ Disponible
          </span>
        </div>

        <div className="mt-7">
          <h2 className="text-base font-bold text-mboa-text">Équipements</h2>
          {logement.equipements.length === 0 ? (
            <p className="mt-2 text-sm text-mboa-text-muted">Non renseignés</p>
          ) : (
            <div className="mt-3 flex flex-wrap gap-2">
              {logement.equipements.map((eq) => (
                <span
                  key={eq}
                  className="rounded-mboa-full border border-mboa-primary/20 bg-mboa-primary/8 px-3 py-1.5 text-xs font-semibold text-mboa-primary"
                >
                  ✓ {eq}
                </span>
              ))}
            </div>
          )}
        </div>

        {proximite.length > 0 && (
          <div className="mt-7">
            <div className="flex items-center justify-between">
              <h2 className="text-base font-bold text-mboa-text">📍 Points de proximité</h2>
              <Link
                href={`/carte?logement=${logement.id}`}
                className="text-xs font-semibold text-mboa-primary"
              >
                Voir sur la carte →
              </Link>
            </div>
            <div className="mt-3 divide-y divide-mboa-border rounded-mboa-lg border border-mboa-border bg-mboa-card">
              {proximite.map((p) => (
                <div key={p.id} className="flex items-center gap-3 px-4 py-3">
                  <span
                    className="flex h-9 w-9 shrink-0 items-center justify-center rounded-mboa-md text-lg"
                    style={{ backgroundColor: `${p.color}1A` }}
                  >
                    {p.icon}
                  </span>
                  <span className="flex-1 truncate text-sm font-medium text-mboa-text">
                    {p.nom}
                  </span>
                  <span
                    className="shrink-0 rounded-mboa-full px-2.5 py-1 text-xs font-bold"
                    style={{ backgroundColor: `${p.color}1A`, color: p.color }}
                  >
                    {formatDistance(p.distanceM)}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        <div className="mt-7">
          <h2 className="text-base font-bold text-mboa-text">👤 Propriétaire</h2>
          <Link
            href={`/vendeur/${logement.proprietaireId}`}
            className="mt-3 flex items-center gap-3.5 rounded-mboa-lg border border-mboa-border bg-mboa-card p-4 shadow-sm"
          >
            <span className="flex h-13 w-13 shrink-0 items-center justify-center rounded-full bg-mboa-primary text-lg font-bold text-white">
              {initiales(logement.proprietaireNom ?? "P")}
            </span>
            <div className="flex-1">
              <p className="text-sm font-bold text-mboa-text">
                {logement.proprietaireNom ?? "Propriétaire"}
              </p>
              <p className="text-xs text-mboa-text-muted">Propriétaire Mboa</p>
            </div>
            {logement.proprietaireVerified && <Badge variant="verified">✅ Vérifié</Badge>}
            <span className="text-mboa-text-muted">›</span>
          </Link>
        </div>

        <div className="mt-7">
          <div className="flex items-center justify-between">
            <h2 className="text-base font-bold text-mboa-text">⭐ Avis ({avis.length})</h2>
            <LaisserAvisButton
              cibleId={logement.proprietaireId}
              annonceId={logement.id}
              isLoggedIn={!!user}
            />
          </div>
          {avis.length === 0 ? (
            <div className="mt-3 rounded-mboa-md bg-mboa-card p-4 text-center text-sm text-mboa-text-muted">
              Aucun avis pour l&apos;instant
            </div>
          ) : (
            <div className="mt-3 space-y-3">
              {avis.map((a) => (
                <div key={a.id} className="rounded-mboa-md bg-mboa-card p-3.5 shadow-sm">
                  <div className="flex items-center gap-2.5">
                    <span className="flex h-9 w-9 items-center justify-center rounded-full bg-mboa-primary-light/30 text-xs font-bold text-mboa-primary">
                      {initiales(a.auteurNom)}
                    </span>
                    <div className="flex-1">
                      <p className="text-sm font-bold text-mboa-text">{a.auteurNom}</p>
                      <p className="text-[11px] text-mboa-text-muted">
                        {formatDateFr(a.datePublication)}
                      </p>
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

        <div className="mt-6">
          <SignalerButton annonceId={logement.id} />
        </div>

        <p className="mt-6 text-center text-xs text-mboa-text-muted">
          👁 {logement.vues} vues · Publié le {formatDateFr(logement.datePublication)}
        </p>
      </div>

      <ContactSticky
        destinataireId={logement.proprietaireId}
        annonceId={logement.id}
        annonceType="logement"
        isLoggedIn={!!user}
      />
    </div>
  );
}
