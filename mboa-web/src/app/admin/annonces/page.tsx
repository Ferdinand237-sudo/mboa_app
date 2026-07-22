import type { Metadata } from "next";
import { getAdminAnnonces } from "@/lib/data/admin";
import { AnnoncesClient } from "@/components/admin/annonces-client";

export const metadata: Metadata = {
  title: "Annonces",
};

// Miroir de AdminAnnoncesScreen (admin_annonces_screen.dart).
export default async function AdminAnnoncesPage() {
  const { logements, articles } = await getAdminAnnonces();
  return <AnnoncesClient logements={logements} articles={articles} />;
}
