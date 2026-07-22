import Link from "next/link";

const GRADIENTS = {
  primary: "from-mboa-primary-dark to-mboa-primary",
  accent: "from-mboa-accent to-mboa-secondary",
} as const;

const TEXT_COLORS = {
  primary: "text-mboa-primary",
  accent: "text-mboa-accent",
} as const;

// Miroir de _buildLimitBanner (logement_screen.dart / market_screen.dart).
export function LimitBanner({
  message,
  variant = "primary",
}: {
  message: string;
  variant?: keyof typeof GRADIENTS;
}) {
  return (
    <div
      className={`rounded-mboa-lg bg-gradient-to-br p-6 text-center ${GRADIENTS[variant]}`}
    >
      <p className="text-3xl">🔒</p>
      <p className="mt-2.5 text-base font-extrabold text-white">
        Connectez-vous pour voir plus
      </p>
      <p className="mt-1.5 text-xs leading-relaxed text-white/85">
        {message}
      </p>
      <Link
        href="/register"
        className={`mt-4 block w-full rounded-mboa-lg bg-white py-3 text-sm font-bold ${TEXT_COLORS[variant]}`}
      >
        Créer un compte
      </Link>
    </div>
  );
}
