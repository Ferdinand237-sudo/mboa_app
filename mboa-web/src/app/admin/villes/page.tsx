import type { Metadata } from "next";
import { getToutesLesVilles } from "@/lib/data/villes";
import { VillesClient } from "@/components/admin/villes-client";

export const metadata: Metadata = {
  title: "Villes couvertes",
};

// Miroir de admin_villes_screen.dart (mobile) : gestion des villes
// couvertes par Mboa sans passer par une republication de l'app/un
// redéploiement du site — voir HISTORIQUE_PROJET_MBOA.md §5bis.
export default async function AdminVillesPage() {
  const villes = await getToutesLesVilles();
  return <VillesClient villes={villes} />;
}
