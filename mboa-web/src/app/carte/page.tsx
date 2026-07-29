import type { Metadata } from "next";
import { getMapData } from "@/lib/data/map";
import { getVilleActuelle } from "@/lib/data/villes";
import { MapLoader } from "@/components/carte/map-loader";

export const metadata: Metadata = {
  title: "Carte",
};

// Miroir de map_screen.dart.
export default async function CartePage({
  searchParams,
}: {
  searchParams: Promise<{ logement?: string }>;
}) {
  const { ville } = await getVilleActuelle();
  const { logements, lieuxPublics } = await getMapData(ville.nom);
  const { logement } = await searchParams;

  return (
    <MapLoader
      logements={logements}
      lieuxPublics={lieuxPublics}
      focusLogementId={logement}
      villeActuelle={ville}
    />
  );
}
