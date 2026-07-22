import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";
import { getVisiteDetail } from "@/lib/data/ambassadeur";
import { PageHeader } from "@/components/ui/page-header";
import { VisiteView } from "@/components/ambassadeur/visite-view";

export const metadata: Metadata = {
  title: "Visite terrain",
};

// Miroir de AmbassadeurVisiteScreen (ambassadeur_visite_screen.dart).
export default async function VisitePage({ params }: { params: Promise<{ id: string }> }) {
  const user = await getCurrentUser();
  const { id } = await params;
  const verification = await getVisiteDetail(id, user!.id);
  if (!verification) notFound();

  return (
    <div>
      <PageHeader title={verification.proprietaireNom} />
      <VisiteView verification={verification} />
    </div>
  );
}
