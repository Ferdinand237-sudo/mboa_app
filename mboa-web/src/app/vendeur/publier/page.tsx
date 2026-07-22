import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";
import { getVendeurPermissions } from "@/lib/data/vendeur-annonces";
import { PublierTabs } from "@/components/vendeur/publier-tabs";

export const metadata: Metadata = {
  title: "Publier une annonce",
};

// Miroir de publier_screen.dart.
export default async function PublierPage() {
  const user = await getCurrentUser();
  if (!user) redirect("/login");

  const permissions = await getVendeurPermissions(user.id);

  if (!permissions.peutLogement && !permissions.peutArticle) {
    return (
      <div className="mx-auto flex min-h-[60vh] max-w-md flex-col items-center justify-center px-8 text-center">
        <span className="text-5xl" aria-hidden>
          🔒
        </span>
        <p className="mt-4 text-base font-bold text-mboa-text">Aucune permission de publication</p>
        <p className="mt-2 text-sm text-mboa-text-muted">
          Ton compte contributeur ne dispose pas encore des droits de publication. Contacte
          l&apos;administrateur.
        </p>
      </div>
    );
  }

  const title =
    permissions.peutLogement && permissions.peutArticle
      ? "➕ Publier"
      : permissions.peutLogement
        ? "🏠 Publier un logement"
        : "🛒 Publier un article";

  return (
    <div>
      <div className="bg-mboa-card px-5 py-5">
        <div className="mx-auto max-w-lg">
          <h1 className="text-xl font-extrabold text-mboa-text">{title}</h1>
          {permissions.peutLogement && permissions.peutArticle && (
            <p className="mt-1 text-sm text-mboa-text-muted">Choisis le type d&apos;annonce à publier</p>
          )}
        </div>
      </div>
      <PublierTabs
        peutLogement={permissions.peutLogement}
        peutArticle={permissions.peutArticle}
        compteActifPublication={permissions.compteActifPublication}
      />
    </div>
  );
}
