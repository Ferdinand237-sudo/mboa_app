import Link from "next/link";

export function HeroHeader({
  prenom,
  hasNotifications,
}: {
  prenom: string;
  hasNotifications: boolean;
}) {
  return (
    <section className="bg-gradient-to-br from-mboa-primary-dark via-mboa-primary to-mboa-primary-light">
      <div className="mx-auto max-w-6xl px-5 pb-8 pt-6 sm:px-6">
        <div className="flex items-start justify-between">
          <div>
            <p className="text-sm text-white/80">Bonjour {prenom} 👋</p>
            <h1 className="text-xl font-extrabold text-white">
              Bienvenue sur Mboa
            </h1>
            <p className="mt-1 flex items-center gap-1 text-xs text-white/70">
              📍 Sangmelima
            </p>
          </div>
          <Link
            href="/profil"
            className="relative flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-white/20 text-lg"
            aria-label="Notifications"
          >
            🔔
            {hasNotifications && (
              <span className="absolute right-2 top-2 h-2.5 w-2.5 rounded-full bg-mboa-secondary" />
            )}
          </Link>
        </div>

        <Link
          href="/logements"
          className="mt-4 flex h-12 items-center rounded-2xl bg-white pl-4 pr-1.5 shadow-lg"
        >
          <span className="text-lg" aria-hidden>
            🔍
          </span>
          <span className="ml-2.5 flex-1 text-sm text-mboa-text-muted">
            Chambre, studio, meublé...
          </span>
          <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-mboa-primary text-white">
            ⚙️
          </span>
        </Link>
      </div>
    </section>
  );
}
