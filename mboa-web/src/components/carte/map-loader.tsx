"use client";

import dynamic from "next/dynamic";
import type { MapLogement, MapLieu } from "@/lib/data/map";

// Leaflet touche `window` au chargement du module : le composant carte doit
// donc être client-only. `ssr:false` n'est autorisé que depuis un Client
// Component, d'où ce petit wrapper séparé de la page serveur.
const MapView = dynamic(() => import("@/components/carte/map-view"), {
  ssr: false,
  loading: () => (
    <div className="flex h-[60vh] items-center justify-center">
      <span className="h-8 w-8 animate-spin rounded-full border-4 border-mboa-primary border-t-transparent" />
    </div>
  ),
});

export function MapLoader(props: {
  logements: MapLogement[];
  lieuxPublics: MapLieu[];
  focusLogementId?: string;
}) {
  return <MapView {...props} />;
}
