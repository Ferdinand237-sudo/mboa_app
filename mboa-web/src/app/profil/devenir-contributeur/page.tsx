import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";
import { PageHeader } from "@/components/ui/page-header";
import { DevenirContributeurForm } from "@/components/profil/devenir-contributeur-form";

export const metadata: Metadata = {
  title: "Devenir contributeur",
};

// Miroir de devenir_contributeur_screen.dart.
export default async function DevenirContributeurPage({
  searchParams,
}: {
  searchParams: Promise<{ dejaVendeur?: string }>;
}) {
  const user = await getCurrentUser();
  if (!user) redirect("/login");

  const { dejaVendeur: dejaVendeurParam } = await searchParams;
  const dejaVendeur = dejaVendeurParam === "1";

  return (
    <div>
      <PageHeader title={dejaVendeur ? "Étendre mes activités" : "Devenir contributeur"} />
      <DevenirContributeurForm dejaVendeur={dejaVendeur} />
    </div>
  );
}
