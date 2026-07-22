import Link from "next/link";

// Miroir de _buildTrouveTonMboaVerrouille dans home_screen.dart.
export function TrouveTonMboaLocked() {
  return (
    <div className="rounded-mboa-lg bg-gradient-to-br from-mboa-primary-dark to-mboa-primary p-5">
      <div className="flex items-center gap-3">
        <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-white/15 text-xl">
          🔒
        </span>
        <h3 className="text-base font-extrabold text-white">
          Trouve ton Mboa 🏘
        </h3>
      </div>
      <p className="mt-3 text-xs leading-relaxed text-white/90">
        Crée ton compte pour accéder à cette fonctionnalité puissante : trouve
        tous les logements autour de toi ou d&apos;un lieu que tu choisis.
      </p>
      <Link
        href="/register"
        className="mt-4 block w-full rounded-mboa-lg bg-white py-3 text-center text-sm font-bold text-mboa-primary"
      >
        Créer un compte
      </Link>
    </div>
  );
}
