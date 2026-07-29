import Link from "next/link";
import { TuneIcon } from "@/components/ui/icons";
import { TourButton } from "@/components/onboarding/tour-button";
import { VilleSwitcher } from "@/components/home/ville-switcher";
import type { TourStep } from "@/components/onboarding/tours";
import type { VilleModel } from "@/lib/data/villes";

// Le badge de notifications non lues vit désormais dans le header persistant
// (NotificationBell, présent sur toutes les pages, live via Supabase
// Realtime) : la cloche ici redevient un simple raccourci, sans dupliquer
// un second indicateur qui pourrait afficher un état différent.
export function HeroHeader({
  prenom,
  tourSteps,
  tourAutoOpenKey,
  villes,
  villeActuelle,
  cookiePresent,
}: {
  prenom: string;
  tourSteps: TourStep[];
  tourAutoOpenKey?: string;
  villes: VilleModel[];
  villeActuelle: VilleModel;
  cookiePresent: boolean;
}) {
  return (
    <section className="rounded-b-[32px] bg-gradient-to-br from-mboa-primary-dark via-mboa-primary to-mboa-primary-light">
      <div className="mx-auto max-w-7xl px-5 pb-8 pt-6 sm:px-6">
        <div className="flex items-start justify-between gap-2">
          <div className="min-w-0 flex-1">
            <p className="text-sm text-white/80">Bonjour {prenom} 👋</p>
            <h1 className="text-xl font-extrabold text-white">
              Bienvenue sur Mboa
            </h1>
            <VilleSwitcher villes={villes} villeActuelle={villeActuelle} cookiePresent={cookiePresent} />
          </div>
          <div className="flex shrink-0 items-center gap-2">
            <TourButton steps={tourSteps} variant="dark" autoOpenKey={tourAutoOpenKey} />
            <Link
              href="/notifications"
              className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-white/20 text-lg"
              aria-label="Notifications"
            >
              🔔
            </Link>
          </div>
        </div>

        <Link
          href="/recherche"
          data-tour="recherche"
          className="mt-4 flex h-12 items-center rounded-2xl bg-white pl-4 pr-1.5 shadow-lg"
        >
          <span className="text-lg" aria-hidden>
            🔍
          </span>
          <span className="ml-2.5 flex-1 text-sm text-mboa-text-muted">
            Chambre, studio, meublé...
          </span>
          <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-mboa-primary text-white">
            <TuneIcon className="h-[18px] w-[18px]" />
          </span>
        </Link>
      </div>
    </section>
  );
}
