"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import L from "leaflet";
import "leaflet.markercluster";
import "leaflet.markercluster/dist/MarkerCluster.css";
import "leaflet.markercluster/dist/MarkerCluster.Default.css";
import { MapContainer, TileLayer, Marker, useMap, useMapEvents } from "react-leaflet";
import { Photo } from "@/components/ui/photo";
import { distanceMetres, formatDistance } from "@/lib/utils/geo";
import { CATEGORIES_LIEUX_PUBLICS, DEFAULT_LAT, DEFAULT_LNG } from "@/lib/constants";
import type { MapLogement, MapLieu } from "@/lib/data/map";

const FILTRES = ["Tous", "Chambre", "Studio", "Appartement", "📍 Lieux"] as const;

function formatPrixCourt(prix: number): string {
  return `${Math.round(prix).toString().replace(/\B(?=(\d{3})+(?!\d))/g, " ")} F`;
}

function iconLogement(prix: number, isSelected: boolean): L.DivIcon {
  const bg = isSelected ? "#1B4332" : "#2D6A4F";
  const w = isSelected ? 120 : 90;
  const h = isSelected ? 50 : 40;
  return L.divIcon({
    className: "",
    html: `<div style="display:flex;flex-direction:column;align-items:center;">
      <div style="background:${bg};color:#fff;font-family:Poppins,sans-serif;font-weight:800;font-size:${isSelected ? 11 : 10}px;padding:5px 8px;border-radius:20px;box-shadow:0 3px ${isSelected ? 12 : 6}px rgba(45,106,79,.4);white-space:nowrap;">${formatPrixCourt(prix)}</div>
      <div style="width:8px;height:8px;border-radius:50%;background:${bg};margin-top:2px;"></div>
    </div>`,
    iconSize: [w, h],
    iconAnchor: [w / 2, h],
  });
}

function iconLieu(cat: { icon: string; color: string }): L.DivIcon {
  return L.divIcon({
    className: "",
    html: `<div style="width:36px;height:36px;border-radius:50%;background:${cat.color}26;border:2px solid ${cat.color};display:flex;align-items:center;justify-content:center;font-size:18px;">${cat.icon}</div>`,
    iconSize: [36, 36],
    iconAnchor: [18, 18],
  });
}

const userIcon = L.divIcon({
  className: "",
  html: `<div style="width:16px;height:16px;border-radius:50%;background:#3b82f6;border:3px solid #fff;box-shadow:0 0 8px rgba(59,130,246,.4);"></div>`,
  iconSize: [22, 22],
  iconAnchor: [11, 11],
});

// Miroir de _buildClusterBadge (map_screen.dart) : badge circulaire coloré,
// bordure blanche 3px, ombre teintée, nombre centré en blanc.
function clusterBadgeIcon(count: number, color: string, size: number): L.DivIcon {
  return L.divIcon({
    className: "",
    html: `<div style="width:${size}px;height:${size}px;border-radius:50%;background:${color};border:3px solid #fff;box-shadow:0 0 8px ${color}66;display:flex;align-items:center;justify-content:center;font-family:Poppins,sans-serif;font-weight:800;font-size:13px;color:#fff;">${count}</div>`,
    iconSize: [size, size],
    iconAnchor: [size / 2, size / 2],
  });
}

// Miroir de MarkerClusterLayerWidget (map_screen.dart) : regroupe les
// marqueurs géographiquement proches en cluster (maxClusterRadius 45px,
// comme côté mobile) via leaflet.markercluster, piloté directement sur
// l'instance Leaflet plutôt qu'un wrapper React (évite les soucis de
// compatibilité de peer dependencies avec React 19).
function ClusterGroup<T>({
  items,
  getPosition,
  getIcon,
  onItemClick,
  clusterColor,
  clusterSize,
}: {
  items: T[];
  getPosition: (item: T) => [number, number];
  getIcon: (item: T) => L.DivIcon;
  onItemClick: (item: T) => void;
  clusterColor: string;
  clusterSize: number;
}) {
  const map = useMap();
  const groupRef = useRef<L.MarkerClusterGroup | null>(null);

  useEffect(() => {
    const group = L.markerClusterGroup({
      maxClusterRadius: 45,
      showCoverageOnHover: false,
      iconCreateFunction: (cluster) => clusterBadgeIcon(cluster.getChildCount(), clusterColor, clusterSize),
    });
    groupRef.current = group;
    map.addLayer(group);
    return () => {
      map.removeLayer(group);
      groupRef.current = null;
    };
  }, [map, clusterColor, clusterSize]);

  useEffect(() => {
    const group = groupRef.current;
    if (!group) return;
    group.clearLayers();
    items.forEach((item) => {
      const marker = L.marker(getPosition(item), { icon: getIcon(item) });
      marker.on("click", () => onItemClick(item));
      group.addLayer(marker);
    });
  }, [items, getPosition, getIcon, onItemClick]);

  return null;
}

function ClickCatcher({ onBackgroundClick }: { onBackgroundClick: () => void }) {
  useMapEvents({ click: onBackgroundClick });
  return null;
}

function MapControls({ center, hasSelection }: { center: [number, number]; hasSelection: boolean }) {
  const map = useMap();
  return (
    <div className={`absolute right-4 z-[1000] flex flex-col gap-2 ${hasSelection ? "bottom-60" : "bottom-5"}`}>
      <button
        type="button"
        aria-label="Recentrer"
        onClick={() => map.setView(center, 14.5)}
        className="flex h-[42px] w-[42px] items-center justify-center rounded-xl bg-white text-mboa-primary shadow-md"
      >
        ✛
      </button>
      <button
        type="button"
        aria-label="Zoomer"
        onClick={() => map.setZoom(map.getZoom() + 1)}
        className="flex h-[42px] w-[42px] items-center justify-center rounded-xl bg-white text-lg font-bold text-mboa-primary shadow-md"
      >
        +
      </button>
      <button
        type="button"
        aria-label="Dézoomer"
        onClick={() => map.setZoom(map.getZoom() - 1)}
        className="flex h-[42px] w-[42px] items-center justify-center rounded-xl bg-white text-lg font-bold text-mboa-primary shadow-md"
      >
        −
      </button>
    </div>
  );
}

type Selection = { type: "logement"; item: MapLogement } | { type: "lieu"; item: MapLieu } | null;

// Miroir de map_screen.dart, y compris le regroupement en clusters
// (flutter_map_marker_cluster côté mobile → leaflet.markercluster ici).
// L'ajout de lieu par l'admin reste hors périmètre web pour l'instant.
export default function MapView({
  logements,
  lieuxPublics,
  focusLogementId,
}: {
  logements: MapLogement[];
  lieuxPublics: MapLieu[];
  focusLogementId?: string;
}) {
  const [filtre, setFiltre] = useState<(typeof FILTRES)[number]>("Tous");
  const [selection, setSelection] = useState<Selection>(() => {
    if (!focusLogementId) return null;
    const match = logements.find((l) => l.id === focusLogementId);
    return match ? { type: "logement", item: match } : null;
  });
  const [userPosition, setUserPosition] = useState<{ lat: number; lng: number } | null>(null);

  useEffect(() => {
    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(
      (pos) => setUserPosition({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
      () => {},
    );
  }, []);

  const center = useMemo((): [number, number] => {
    const focus = focusLogementId ? logements.find((l) => l.id === focusLogementId) : null;
    return focus ? [focus.lat, focus.lng] : [DEFAULT_LAT, DEFAULT_LNG];
  }, [focusLogementId, logements]);

  const logementsFiltres = useMemo(() => {
    if (filtre === "Tous") return logements;
    if (filtre === "📍 Lieux") return [];
    return logements.filter((l) => l.type === filtre);
  }, [logements, filtre]);

  const afficherLogements = filtre !== "📍 Lieux";
  const afficherLieux = filtre === "Tous" || filtre === "📍 Lieux";

  function distanceUtilisateur(lat: number, lng: number): string {
    if (!userPosition) return "";
    return `${formatDistance(distanceMetres(userPosition.lat, userPosition.lng, lat, lng))} de vous`;
  }

  function ouvrirItineraire(lat: number, lng: number) {
    const origine = userPosition ? `${userPosition.lat},${userPosition.lng}` : "";
    const url = `https://www.google.com/maps/dir/?api=1&origin=${origine}&destination=${lat},${lng}&travelmode=walking`;
    window.open(url, "_blank", "noopener,noreferrer");
  }

  return (
    <div>
      <div className="bg-white px-5 pb-3 pt-4">
        <div className="mx-auto max-w-6xl">
          <h1 className="text-[22px] font-extrabold text-mboa-text">🗺️ Carte</h1>
          <p className="mt-1 text-xs text-mboa-text-muted">
            Sangmelima · {logements.length} logement{logements.length > 1 ? "s" : ""} ·{" "}
            {lieuxPublics.length} lieu{lieuxPublics.length > 1 ? "x" : ""}
          </p>
          <div className="mt-3 flex gap-2 overflow-x-auto pb-1">
            {FILTRES.map((f) => {
              const isSelected = filtre === f;
              return (
                <button
                  key={f}
                  type="button"
                  onClick={() => setFiltre(f)}
                  className={`shrink-0 rounded-full border-[1.5px] px-3.5 py-1.5 text-xs font-semibold ${
                    isSelected
                      ? "border-mboa-primary bg-mboa-primary text-white"
                      : "border-mboa-border bg-white text-mboa-text"
                  }`}
                >
                  {f}
                </button>
              );
            })}
          </div>
        </div>
      </div>

      <div className="relative h-[calc(100vh-190px)] min-h-[420px] w-full">
        <MapContainer center={center} zoom={14.5} className="h-full w-full" scrollWheelZoom>
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          <ClickCatcher onBackgroundClick={() => setSelection(null)} />

          {userPosition && <Marker position={[userPosition.lat, userPosition.lng]} icon={userIcon} />}

          {afficherLogements && (
            <ClusterGroup
              items={logementsFiltres}
              getPosition={(l) => [l.lat, l.lng]}
              getIcon={(l) => iconLogement(l.prix, selection?.type === "logement" && selection.item.id === l.id)}
              onItemClick={(l) => setSelection({ type: "logement", item: l })}
              clusterColor="#2D6A4F"
              clusterSize={36}
            />
          )}

          {afficherLieux && (
            <ClusterGroup
              items={lieuxPublics}
              getPosition={(lieu) => [lieu.lat, lieu.lng]}
              getIcon={(lieu) => iconLieu(CATEGORIES_LIEUX_PUBLICS[lieu.categorie] ?? CATEGORIES_LIEUX_PUBLICS.autre)}
              onItemClick={(lieu) => setSelection({ type: "lieu", item: lieu })}
              clusterColor="#E76F51"
              clusterSize={32}
            />
          )}

          <MapControls center={center} hasSelection={selection !== null} />
        </MapContainer>

        {selection?.type === "logement" && (
          <FicheLogement
            logement={selection.item}
            onItineraire={() => ouvrirItineraire(selection.item.lat, selection.item.lng)}
          />
        )}
        {selection?.type === "lieu" && (
          <FicheLieu
            lieu={selection.item}
            distance={distanceUtilisateur(selection.item.lat, selection.item.lng)}
            onItineraire={() => ouvrirItineraire(selection.item.lat, selection.item.lng)}
          />
        )}
      </div>
    </div>
  );
}

function FicheLogement({ logement, onItineraire }: { logement: MapLogement; onItineraire: () => void }) {
  return (
    <div className="absolute inset-x-0 bottom-0 z-[1000] mx-4 mb-4 rounded-mboa-xl bg-white shadow-2xl">
      <div className="mx-auto mt-2.5 h-1 w-10 rounded-full bg-mboa-border" />
      <div className="flex gap-3.5 p-4">
        <div className="relative h-[90px] w-[90px] shrink-0 overflow-hidden rounded-xl bg-gradient-to-br from-mboa-primary to-mboa-primary-light">
          <Photo src={logement.photos[0]} alt={logement.titre} />
        </div>
        <div className="min-w-0 flex-1">
          <p className="line-clamp-2 text-sm font-bold text-mboa-text">{logement.titre}</p>
          <p className="mt-1 flex items-center gap-1 text-xs text-mboa-text-muted">
            📍 {logement.quartier ?? "Sangmelima"}
          </p>
          <p className="mt-1.5 text-base font-extrabold text-mboa-primary">
            {formatPrixCourt(logement.prix)}/mois
          </p>
          <div className="mt-1 flex gap-1">
            {logement.boosted && (
              <span className="rounded-full bg-mboa-boost/15 px-1.5 py-0.5 text-[9px] font-bold text-mboa-boost">
                🔥
              </span>
            )}
            {logement.proprietaireVerified && (
              <span className="rounded-full bg-mboa-verified/15 px-1.5 py-0.5 text-[9px] font-bold text-mboa-verified">
                ✅
              </span>
            )}
          </div>
        </div>
      </div>
      <div className="flex gap-2.5 px-4 pb-4">
        <button
          type="button"
          onClick={onItineraire}
          className="flex-1 rounded-mboa-md border-[1.5px] border-mboa-primary py-2.5 text-[13px] font-semibold text-mboa-primary"
        >
          🧭 Itinéraire
        </button>
        <Link
          href={`/logements/${logement.id}`}
          className="flex-[2] rounded-mboa-md bg-mboa-primary py-2.5 text-center text-[13px] font-semibold text-white"
        >
          👁 Voir le logement
        </Link>
      </div>
    </div>
  );
}

function FicheLieu({
  lieu,
  distance,
  onItineraire,
}: {
  lieu: MapLieu;
  distance: string;
  onItineraire: () => void;
}) {
  const cat = CATEGORIES_LIEUX_PUBLICS[lieu.categorie] ?? CATEGORIES_LIEUX_PUBLICS.autre;
  return (
    <div className="absolute inset-x-0 bottom-0 z-[1000] mx-4 mb-4 rounded-mboa-xl bg-white p-4 shadow-2xl">
      <div className="mx-auto mb-3.5 h-1 w-10 rounded-full bg-mboa-border" />
      <div className="flex items-center gap-3.5">
        <span
          className="flex h-[50px] w-[50px] shrink-0 items-center justify-center rounded-2xl text-2xl"
          style={{ backgroundColor: `${cat.color}1f` }}
        >
          {cat.icon}
        </span>
        <div className="min-w-0 flex-1">
          <p className="text-[15px] font-extrabold text-mboa-text">{lieu.nom}</p>
          <p className="mt-0.5 text-xs font-semibold" style={{ color: cat.color }}>
            {distance ? `${cat.label} · ${distance}` : cat.label}
          </p>
        </div>
      </div>
      <div className="mt-4 flex gap-2.5">
        <button
          type="button"
          onClick={onItineraire}
          className="flex-1 rounded-mboa-md border-[1.5px] border-mboa-primary py-2.5 text-[13px] font-semibold text-mboa-primary"
        >
          🧭 Itinéraire
        </button>
        <Link
          href={`/carte/autour?lieu=${encodeURIComponent(lieu.nom)}&lat=${lieu.lat}&lng=${lieu.lng}`}
          className="flex-[2] rounded-mboa-md bg-mboa-primary py-2.5 text-center text-[13px] font-semibold text-white"
        >
          🔍 Autour de ce lieu
        </Link>
      </div>
    </div>
  );
}
