import type { Metadata } from "next";
import { RechercheClient } from "@/components/home/recherche-client";

export const metadata: Metadata = {
  title: "Recherche",
};

// Miroir de home_search_screen.dart.
export default function RecherchePage() {
  return <RechercheClient />;
}
