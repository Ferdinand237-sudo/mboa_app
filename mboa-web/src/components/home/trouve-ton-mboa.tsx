"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { fetchLogementsProches, type LogementProche } from "@/lib/data/proximite-client";
import { formatPrix } from "@/lib/utils/format";
import { distanceMetres } from "@/lib/utils/geo";
import { Photo } from "@/components/ui/photo";
import type { LieuPublic } from "@/lib/data/home";
import { DEFAULT_LAT, DEFAULT_LNG, DEFAULT_VILLE } from "@/lib/constants";

const RAYONS_KM = [0.5, 1, 1.5, 2, 3, 5];

function formatDistanceKm(km: number) {
  return km < 1 ? `${Math.round(km * 1000)} m` : `${km.toFixed(1)} km`;
}

function formatRayon(km: number) {
  return km < 1 ? `${Math.round(km * 1000)} m` : `${km % 1 === 0 ? km.toFixed(0) : km} km`;
}

// Miroir de _buildTrouveTonMboa dans home_screen.dart : géolocalisation
// navigateur (ou lieu choisi manuellement) + RPC logements_proches.
export function TrouveTonMboa({ lieuxPublics }: { lieuxPublics: LieuPublic[] }) {
  const [refLat, setRefLat] = useState(DEFAULT_LAT);
  const [refLng, setRefLng] = useState(DEFAULT_LNG);
  const [refNom, setRefNom] = useState(DEFAULT_VILLE);
  const [rayonKm, setRayonKm] = useState(2);
  const [result, setResult] = useState<{ key: string; data: LogementProche[] } | null>(null);
  const [pickerOpen, setPickerOpen] = useState(false);

  const searchKey = `${refLat}-${refLng}-${rayonKm}`;
  const loading = result?.key !== searchKey;
  const logements = result?.key === searchKey ? result.data : [];

  useEffect(() => {
    if (!("geolocation" in navigator)) return;
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude } = position.coords;
        const distanceM = distanceMetres(latitude, longitude, DEFAULT_LAT, DEFAULT_LNG);
        if (distanceM <= 30000) {
          setRefLat(latitude);
          setRefLng(longitude);
          setRefNom("ta position");
        }
      },
      () => {},
      { timeout: 8000 },
    );
  }, []);

  useEffect(() => {
    let cancelled = false;
    fetchLogementsProches(refLat, refLng, rayonKm).then((data) => {
      if (!cancelled) {
        setResult({ key: searchKey, data });
      }
    });
    return () => {
      cancelled = true;
    };
  }, [refLat, refLng, rayonKm, searchKey]);

  function choisirLieu(lieu: LieuPublic) {
    setRefLat(lieu.lat);
    setRefLng(lieu.lng);
    setRefNom(lieu.nom);
    setPickerOpen(false);
  }

  return (
    <div className="relative rounded-mboa-lg bg-gradient-to-br from-mboa-primary-dark to-mboa-primary p-5">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h3 className="text-base font-extrabold text-white">
            Trouve ton Mboa 🏘
          </h3>
          <p className="mt-1 text-xs text-white/85">
            Logements autour de {refNom}
          </p>
        </div>
        <button
          onClick={() => setPickerOpen((v) => !v)}
          className="shrink-0 rounded-mboa-md bg-white/20 px-2.5 py-1.5 text-[11px] font-bold text-white"
        >
          Changer 📍
        </button>
      </div>

      {pickerOpen && (
        <div className="absolute right-5 top-14 z-10 max-h-64 w-64 overflow-y-auto rounded-mboa-md bg-white p-2 shadow-xl">
          <p className="px-2 py-1.5 text-xs font-bold text-mboa-text">
            Choisir un lieu de référence
          </p>
          {lieuxPublics.length === 0 ? (
            <p className="px-2 py-3 text-xs text-mboa-text-muted">
              Aucun lieu enregistré pour le moment
            </p>
          ) : (
            lieuxPublics.map((lieu) => (
              <button
                key={lieu.id}
                onClick={() => choisirLieu(lieu)}
                className="block w-full rounded-mboa-sm px-2 py-2 text-left text-sm text-mboa-text hover:bg-mboa-background"
              >
                📍 {lieu.nom}
              </button>
            ))
          )}
        </div>
      )}

      <div className="mt-3.5 flex gap-2 overflow-x-auto pb-1">
        {RAYONS_KM.map((r) => (
          <button
            key={r}
            onClick={() => setRayonKm(r)}
            className={`shrink-0 rounded-mboa-full px-3 py-1.5 text-[11px] font-bold ${
              rayonKm === r
                ? "bg-white text-mboa-primary"
                : "bg-white/15 text-white"
            }`}
          >
            {formatRayon(r)}
          </button>
        ))}
      </div>

      <div className="mt-3.5">
        {loading ? (
          <div className="flex h-[150px] items-center justify-center">
            <span className="h-6 w-6 animate-spin rounded-full border-2 border-white border-t-transparent" />
          </div>
        ) : logements.length === 0 ? (
          <p className="py-4 text-xs text-white/85">
            Aucun logement dans ce rayon pour l&apos;instant
          </p>
        ) : (
          <div className="flex gap-2.5 overflow-x-auto pb-1">
            {logements.map((l) => (
              <Link
                key={l.id}
                href={`/logements/${l.id}`}
                className="w-[150px] shrink-0 overflow-hidden rounded-mboa-md bg-white"
              >
                <div className="relative h-20 w-full bg-gradient-to-br from-mboa-primary to-mboa-primary-light">
                  <Photo src={l.photos[0]} alt={l.titre} />
                </div>
                <div className="p-2">
                  <p className="truncate text-[11px] font-bold text-mboa-text">
                    {l.titre}
                  </p>
                  <p className="text-[11px] font-extrabold text-mboa-primary">
                    {formatPrix(l.prix)}
                  </p>
                  <p className="text-[9px] text-mboa-text-muted">
                    🚶 {formatDistanceKm(l.distanceKm)}
                  </p>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>

      <Link
        href={`/proximite?lat=${refLat}&lng=${refLng}&nom=${encodeURIComponent(refNom)}&rayon=${rayonKm}`}
        className="mt-3.5 block w-full rounded-mboa-lg bg-white py-3 text-center text-sm font-bold text-mboa-primary"
      >
        Voir tous les résultats →
      </Link>
    </div>
  );
}
