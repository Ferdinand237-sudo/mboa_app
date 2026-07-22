import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";
import { getAlertes } from "@/lib/data/alertes";
import { PageHeader } from "@/components/ui/page-header";
import { AlertesList } from "@/components/profil/alertes-list";

export const metadata: Metadata = {
  title: "Mes alertes de recherche",
};

// Miroir de alertes_recherche_screen.dart.
export default async function AlertesPage() {
  const user = await getCurrentUser();
  if (!user) redirect("/login");

  const alertes = await getAlertes(user.id);

  return (
    <div>
      <PageHeader title="🔔 Mes alertes de recherche" />
      <AlertesList alertes={alertes} />
    </div>
  );
}
