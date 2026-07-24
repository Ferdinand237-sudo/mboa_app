"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import { Photo } from "@/components/ui/photo";
import { RAYONS_RECHERCHE_KM } from "@/lib/constants";

type ResultatLogement = { id: string; titre: string; prix: number; photos: string[]; distance_km: number };
type ResultatArticle = { id: string; titre: string; prix: number; photos: string[]; distance_km: number };

function formatPrix(prix: number): string {
  return `${Math.round(prix).toString().replace(/\B(?=(\d{3})+(?!\d))/g, " ")} F`;
}

function formatRayon(km: number): string {
  return km < 1 ? `${Math.round(km * 1000)} m` : `${km.toFixed(1)} km`;
}

function formatDistanceRpc(distanceKm: number): string {
  return distanceKm < 1 ? `${Math.round(distanceKm * 1000)} m` : `${distanceKm.toFixed(1)} km`;
}

// Miroir de lieux_recherche_resultats_screen.dart.
export function AutourDeCeLieu({ lieuNom, lat, lng }: { lieuNom: string; lat: number; lng: number }) {
  const [rayonIndex, setRayonIndex] = useState(2);
  const rayonKm = RAYONS_RECHERCHE_KM[rayonIndex];
  const [tab, setTab] = useState<"logements" | "articles">("logements");
  const searchKey = `${lat}:${lng}:${rayonKm}`;
  const [result, setResult] = useState<{
    key: string;
    logements: ResultatLogement[];
    articles: ResultatArticle[];
  }>({ key: "", logements: [], articles: [] });
  const loading = result.key !== searchKey;
  const logements = result.key === searchKey ? result.logements : [];
  const articles = result.key === searchKey ? result.articles : [];

  useEffect(() => {
    const supabase = createClient();
    Promise.all([
      supabase.rpc("logements_proches", { p_lat: lat, p_lng: lng, p_rayon_km: rayonKm }),
      supabase.rpc("articles_proches", { p_lat: lat, p_lng: lng, p_rayon_km: rayonKm }),
    ]).then(([logementsRes, articlesRes]) => {
      setResult({ key: searchKey, logements: logementsRes.data ?? [], articles: articlesRes.data ?? [] });
    });
  }, [lat, lng, rayonKm, searchKey]);

  return (
    <div>
      <div className="bg-white px-5 pb-3 pt-4">
        <div className="mx-auto max-w-2xl">
          <h1 className="text-[15px] font-bold text-mboa-text">📍 Autour de {lieuNom}</h1>
          <div className="mt-3 flex gap-1 border-b border-mboa-border">
            <button
              type="button"
              onClick={() => setTab("logements")}
              className={`border-b-[3px] px-4 py-2.5 text-[13px] font-bold ${
                tab === "logements" ? "border-mboa-primary text-mboa-primary" : "border-transparent text-mboa-text-muted"
              }`}
            >
              🏠 Logements ({logements.length})
            </button>
            <button
              type="button"
              onClick={() => setTab("articles")}
              className={`border-b-[3px] px-4 py-2.5 text-[13px] font-bold ${
                tab === "articles" ? "border-mboa-primary text-mboa-primary" : "border-transparent text-mboa-text-muted"
              }`}
            >
              🛒 Market ({articles.length})
            </button>
          </div>
        </div>
      </div>

      <div className="rounded-b-[32px] bg-white px-5 pb-3 pt-1 shadow-sm">
        <div className="mx-auto max-w-2xl">
          <p className="text-xs font-semibold text-mboa-text">Rayon de recherche : {formatRayon(rayonKm)}</p>
          <input
            type="range"
            min={0}
            max={RAYONS_RECHERCHE_KM.length - 1}
            step={1}
            value={rayonIndex}
            onChange={(e) => setRayonIndex(Number(e.target.value))}
            className="mt-2 w-full accent-mboa-primary"
          />
        </div>
      </div>

      <div className="mx-auto max-w-2xl px-4 py-4 pb-10">
        {loading ? (
          <div className="flex justify-center py-20">
            <span className="h-8 w-8 animate-spin rounded-full border-4 border-mboa-primary border-t-transparent" />
          </div>
        ) : tab === "logements" ? (
          <ListeResultats
            items={logements}
            emoji="🏠"
            prixSuffix="/mois"
            hrefBase="/logements"
            videMessage="Aucun logement dans ce rayon"
          />
        ) : (
          <ListeResultats
            items={articles}
            emoji="📦"
            prixSuffix=""
            hrefBase="/marketplace"
            videMessage="Aucun article dans ce rayon"
          />
        )}
      </div>
    </div>
  );
}

function ListeResultats({
  items,
  emoji,
  prixSuffix,
  hrefBase,
  videMessage,
}: {
  items: (ResultatLogement | ResultatArticle)[];
  emoji: string;
  prixSuffix: string;
  hrefBase: string;
  videMessage: string;
}) {
  if (items.length === 0) {
    return (
      <div className="flex flex-col items-center py-16 text-center">
        <span className="text-5xl" aria-hidden>
          🔍
        </span>
        <p className="mt-3 text-sm text-mboa-text-muted">{videMessage}</p>
        <p className="mt-1 text-xs text-mboa-text-muted">Essayez d&apos;élargir le rayon de recherche</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-3">
      {items.map((item) => (
        <Link
          key={item.id}
          href={`${hrefBase}/${item.id}`}
          className="flex items-center gap-3 rounded-mboa-lg bg-mboa-card p-3 shadow-sm"
        >
          <div className="relative h-20 w-20 shrink-0 overflow-hidden rounded-xl bg-gradient-to-br from-mboa-primary to-mboa-primary-light">
            <Photo src={item.photos[0]} alt={item.titre} />
            <span className="sr-only">{emoji}</span>
          </div>
          <div className="min-w-0 flex-1">
            <p className="truncate text-[13px] font-bold text-mboa-text">{item.titre}</p>
            <p className="mt-1 text-sm font-extrabold text-mboa-primary">
              {formatPrix(item.prix)}
              {prixSuffix}
            </p>
            <span className="mt-1.5 inline-flex items-center gap-1 rounded-full bg-mboa-primary/10 px-2 py-1 text-[10px] font-bold text-mboa-primary">
              🚶 {formatDistanceRpc(item.distance_km)}
            </span>
          </div>
        </Link>
      ))}
    </div>
  );
}
