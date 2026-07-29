import type { Metadata } from "next";
import { getLogements } from "@/lib/data/logements";
import { getCurrentUser } from "@/lib/data/auth";
import { getVilleActuelle } from "@/lib/data/villes";
import { LogementsClient } from "@/components/logement/logements-client";

export const metadata: Metadata = {
  title: "Logements",
  description:
    "Chambres, studios et appartements disponibles à Sangmelima, Kribi et Ébolowa pour les étudiants.",
};

export default async function LogementsPage() {
  const { ville } = await getVilleActuelle();
  const [logements, user] = await Promise.all([
    getLogements({ ville: ville.nom, prixMax: 60000, limit: 200 }),
    getCurrentUser(),
  ]);

  return (
    <LogementsClient initialLogements={logements} isLoggedIn={!!user} />
  );
}
