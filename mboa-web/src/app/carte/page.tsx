import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Carte",
};

export default function CartePage() {
  return (
    <div className="mx-auto flex min-h-[60vh] max-w-md flex-col items-center justify-center px-4 text-center">
      <span className="text-4xl" aria-hidden>
        🗺️
      </span>
      <h1 className="mt-4 text-xl font-extrabold text-mboa-text">
        Carte bientôt disponible
      </h1>
      <p className="mt-2 text-sm text-mboa-text-muted">
        La carte interactive de Sangmelima (logements, campus, hôpital,
        marché...) arrive prochainement sur le web. Utilise en attendant la
        section &quot;Trouve ton Mboa&quot; sur l&apos;accueil.
      </p>
    </div>
  );
}
