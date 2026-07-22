import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";
import { getAvisAModerer } from "@/lib/data/avis-moderation";
import { PageHeader } from "@/components/ui/page-header";
import { AvisModerationList } from "@/components/profil/avis-moderation-list";

export const metadata: Metadata = {
  title: "Avis à modérer",
};

// Miroir de avis_moderation_screen.dart.
export default async function AvisModerationPage() {
  const user = await getCurrentUser();
  if (!user) redirect("/login");

  const avis = await getAvisAModerer(user.id);

  return (
    <div>
      <PageHeader title="⭐ Avis à modérer" />
      <AvisModerationList avis={avis} />
    </div>
  );
}
