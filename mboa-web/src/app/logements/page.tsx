import type { Metadata } from "next";
import { getLogements } from "@/lib/data/logements";
import { getCurrentUser } from "@/lib/data/auth";
import { LogementsClient } from "@/components/logement/logements-client";

export const metadata: Metadata = {
  title: "Logements à Sangmelima",
  description:
    "Chambres, studios et appartements disponibles à Sangmelima pour les étudiants.",
};

export default async function LogementsPage() {
  const [logements, user] = await Promise.all([
    getLogements({ prixMax: 60000, limit: 200 }),
    getCurrentUser(),
  ]);

  return (
    <LogementsClient initialLogements={logements} isLoggedIn={!!user} />
  );
}
