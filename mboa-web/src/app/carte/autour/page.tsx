import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { AutourDeCeLieu } from "@/components/carte/autour-de-ce-lieu";

export const metadata: Metadata = {
  title: "Autour de ce lieu",
};

// Miroir de lieux_recherche_resultats_screen.dart.
export default async function AutourPage({
  searchParams,
}: {
  searchParams: Promise<{ lieu?: string; lat?: string; lng?: string }>;
}) {
  const { lieu, lat, lng } = await searchParams;
  const latNum = lat ? Number(lat) : NaN;
  const lngNum = lng ? Number(lng) : NaN;
  if (!lieu || Number.isNaN(latNum) || Number.isNaN(lngNum)) notFound();

  return <AutourDeCeLieu lieuNom={lieu} lat={latNum} lng={lngNum} />;
}
