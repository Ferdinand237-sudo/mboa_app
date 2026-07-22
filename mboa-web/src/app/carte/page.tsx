import type { Metadata } from "next";
import { getMapData } from "@/lib/data/map";
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
  const { logements, lieuxPublics } = await getMapData();
  const { logement } = await searchParams;

  return <MapLoader logements={logements} lieuxPublics={lieuxPublics} focusLogementId={logement} />;
}
