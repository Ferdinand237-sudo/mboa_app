import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";
import { getFavoris } from "@/lib/data/favoris-list";
import { PageHeader } from "@/components/ui/page-header";
import { FavoriCard } from "@/components/profil/favori-card";

export const metadata: Metadata = {
  title: "Mes favoris",
};

// Miroir de favoris_screen.dart.
export default async function FavorisPage() {
  const user = await getCurrentUser();
  if (!user) redirect("/login");

  const favoris = await getFavoris(user.id);

  return (
    <div>
      <PageHeader title="❤️ Mes favoris" />

      <div className="mx-auto max-w-2xl px-5 pb-10">
        {favoris.length === 0 ? (
          <div className="flex flex-col items-center py-20 text-center">
            <span className="text-5xl" aria-hidden>
              💔
            </span>
            <p className="mt-4 text-base font-bold text-mboa-text">Aucun favori pour l&apos;instant</p>
            <p className="mt-2 max-w-xs text-sm text-mboa-text-muted">
              Ajoutez des logements ou articles à vos favoris en appuyant sur le cœur
            </p>
          </div>
        ) : (
          <div className="flex flex-col gap-3.5">
            {favoris.map((item) => (
              <FavoriCard key={`${item.type}-${item.id}`} item={item} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
