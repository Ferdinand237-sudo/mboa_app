import type { Metadata } from "next";
import { getAdminDemandes } from "@/lib/data/admin";
import { DemandesClient } from "@/components/admin/demandes-client";

export const metadata: Metadata = {
  title: "Demandes Pro",
};

// Miroir de AdminDemandesScreen (admin_demandes_screen.dart).
export default async function AdminDemandesPage() {
  const demandes = await getAdminDemandes();
  return <DemandesClient demandes={demandes} />;
}
