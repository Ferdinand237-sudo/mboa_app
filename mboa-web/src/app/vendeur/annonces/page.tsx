import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";
import { getVendeurPermissions, getMesAnnonces } from "@/lib/data/vendeur-annonces";
import { GestionTabs } from "@/components/vendeur/gestion-tabs";

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
      <div className="bg-mboa-card px-5 py-5">
        <h1 className="mx-auto max-w-2xl text-xl font-extrabold text-mboa-text">📋 Gestion</h1>
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
