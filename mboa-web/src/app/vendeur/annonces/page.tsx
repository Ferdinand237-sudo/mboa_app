import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";
import { getVendeurPermissions, getMesAnnonces } from "@/lib/data/vendeur-annonces";
import { GestionTabs } from "@/components/vendeur/gestion-tabs";
import { TourButton } from "@/components/onboarding/tour-button";
import { TOUR_GESTION } from "@/components/onboarding/tours";

export const metadata: Metadata = {
  title: "Mes annonces",
};

// Miroir de gestion_screen.dart.
export default async function AnnoncesPage() {
  const user = await getCurrentUser();
  if (!user) redirect("/login");

  const permissions = await getVendeurPermissions(user.id);

  if (!permissions.peutLogement && !permissions.peutArticle) {
    return (
      <div className="mx-auto flex min-h-[60vh] max-w-md flex-col items-center justify-center px-8 text-center">
        <p className="text-sm text-mboa-text-muted">Aucune annonce à gérer</p>
      </div>
    );
  }

  const { logements, articles } = await getMesAnnonces(user.id, permissions);

  return (
    <div>
      <div data-tour="gestion-hero" className="rounded-b-[32px] bg-mboa-card px-5 py-5 shadow-sm">
        <div className="mx-auto flex max-w-2xl items-center justify-between gap-2">
          <h1 className="text-xl font-extrabold text-mboa-text">📋 Gestion</h1>
          <TourButton steps={TOUR_GESTION} variant="light" />
        </div>
      </div>
      <GestionTabs
        peutLogement={permissions.peutLogement}
        peutArticle={permissions.peutArticle}
        logements={logements}
        articles={articles}
      />
    </div>
  );
}
