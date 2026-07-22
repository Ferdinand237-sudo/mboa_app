import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";
import { getLogementsProches, getArticlesProches } from "@/lib/data/proximite";
import { formatPrix } from "@/lib/utils/format";
import { Photo } from "@/components/ui/photo";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Résultats autour de toi",
};

function formatDistance(km: number) {
  return km < 1 ? `${Math.round(km * 1000)} m` : `${km.toFixed(1)} km`;
}

export default async function ProximitePage({
  searchParams,
}: {
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}) {
  const user = await getCurrentUser();
  if (!user) redirect("/login");

  const params = await searchParams;
  const lat = Number(params.lat ?? 0);
  const lng = Number(params.lng ?? 0);
  const nom = typeof params.nom === "string" ? params.nom : "ce lieu";
  const rayon = Number(params.rayon ?? 1.5);

  const [logements, articles] = await Promise.all([
    getLogementsProches(lat, lng, rayon),
    getArticlesProches(lat, lng, rayon),
  ]);

  return (
    <div className="mx-auto max-w-6xl px-4 py-8 sm:px-6">
      <h1 className="text-2xl font-extrabold text-mboa-text">
        Autour de {nom}
      </h1>
      <p className="mt-1 text-sm text-mboa-text-muted">
        Rayon de {rayon} km — {logements.length} logement
        {logements.length > 1 ? "s" : ""}, {articles.length} article
        {articles.length > 1 ? "s" : ""}
      </p>

      <h2 className="mt-8 text-lg font-bold text-mboa-text">🏘 Logements</h2>
      {logements.length === 0 ? (
        <p className="mt-3 text-sm text-mboa-text-muted">
          Aucun logement dans ce rayon.
        </p>
      ) : (
        <div className="mt-3 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
          {logements.map((l) => (
            <Link
              key={l.id}
              href={`/logements/${l.id}`}
              className="overflow-hidden rounded-mboa-lg bg-mboa-card shadow-sm"
            >
              <div className="relative aspect-[4/3] w-full bg-gradient-to-br from-mboa-primary to-mboa-primary-light">
                <Photo src={l.photos[0]} alt={l.titre} />
              </div>
              <div className="p-2.5">
                <p className="truncate text-xs font-bold text-mboa-text">
                  {l.titre}
                </p>
                <p className="text-sm font-extrabold text-mboa-primary">
                  {formatPrix(l.prix)}
                </p>
                <p className="text-[11px] text-mboa-text-muted">
                  🚶 {formatDistance(l.distanceKm)}
                </p>
              </div>
            </Link>
          ))}
        </div>
      )}

      <h2 className="mt-10 text-lg font-bold text-mboa-text">🛒 Articles</h2>
      {articles.length === 0 ? (
        <p className="mt-3 text-sm text-mboa-text-muted">
          Aucun article dans ce rayon.
        </p>
      ) : (
        <div className="mt-3 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
          {articles.map((a) => (
            <Link
              key={a.id}
              href={`/marketplace/${a.id}`}
              className="overflow-hidden rounded-mboa-lg bg-mboa-card shadow-sm"
            >
              <div className="relative aspect-square w-full bg-gradient-to-br from-mboa-secondary/30 to-mboa-accent/20">
                <Photo src={a.photos[0]} alt={a.titre} />
              </div>
              <div className="p-2.5">
                <p className="truncate text-xs font-bold text-mboa-text">
                  {a.titre}
                </p>
                <p className="text-sm font-extrabold text-mboa-accent">
                  {formatPrix(a.prix)}
                </p>
                <p className="text-[11px] text-mboa-text-muted">
                  🚶 {formatDistance(a.distanceKm)}
                </p>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
