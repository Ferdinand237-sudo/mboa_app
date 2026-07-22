import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";
import { PageHeader } from "@/components/ui/page-header";
import { EditProfilForm } from "@/components/profil/edit-profil-form";

export const metadata: Metadata = {
  title: "Modifier mon profil",
};

// Miroir de edit_profil_screen.dart.
export default async function EditProfilPage() {
  const user = await getCurrentUser();
  if (!user) redirect("/login");

  return (
    <div>
      <PageHeader title="Modifier mon profil" />
      <EditProfilForm user={user} />
    </div>
  );
}
