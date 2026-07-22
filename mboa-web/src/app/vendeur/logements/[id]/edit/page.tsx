import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";
import { getLogementAModifier } from "@/lib/data/vendeur-annonces";
import { PageHeader } from "@/components/ui/page-header";
import { EditLogementForm } from "@/components/vendeur/edit-logement-form";

export const metadata: Metadata = {
  title: "Modifier le logement",
};

// Miroir de edit_logement_screen.dart.
export default async function EditLogementPage({ params }: { params: Promise<{ id: string }> }) {
  const user = await getCurrentUser();
  if (!user) redirect("/login");

  const { id } = await params;
  const logement = await getLogementAModifier(id, user.id);
  if (!logement) notFound();

  return (
    <div>
      <PageHeader title="✏️ Modifier le logement" />
      <EditLogementForm logement={logement} />
    </div>
  );
}
