"use client";

import { useEffect, useState } from "react";
import { GuidedTour } from "@/components/onboarding/guided-tour";
import type { TourStep } from "@/components/onboarding/tours";

// Bouton "🧭 Comment utiliser ?" posé dans le coin droit de chaque section
// hero (accueil, Publier, Gestion...). Au clic, lance la visite guidée
// correspondante ; refermable à tout moment (✕, Passer, clic en dehors).
// Avec autoOpenKey, la visite se lance aussi automatiquement une seule fois
// (mémorisé en localStorage) — utilisé uniquement pour l'accueil visiteur
// non connecté, cf. page.tsx.
export function TourButton({
  steps,
  variant = "light",
  autoOpenKey,
  label = "Comment utiliser ?",
}: {
  steps: TourStep[];
  variant?: "light" | "dark";
  autoOpenKey?: string;
  label?: string;
}) {
  const [open, setOpen] = useState(false);

  useEffect(() => {
    if (!autoOpenKey) return;
    if (localStorage.getItem(autoOpenKey) === "1") return;
    const t = setTimeout(() => setOpen(true), 900);
    return () => clearTimeout(t);
  }, [autoOpenKey]);

  function fermer() {
    if (autoOpenKey) localStorage.setItem(autoOpenKey, "1");
    setOpen(false);
  }

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className={`flex shrink-0 items-center gap-1.5 whitespace-nowrap rounded-full px-3 py-1.5 text-xs font-bold ${
          variant === "dark"
            ? "bg-white/15 text-white ring-1 ring-inset ring-white/40"
            : "bg-mboa-primary/8 text-mboa-primary ring-1 ring-inset ring-mboa-primary/20"
        }`}
      >
        <span aria-hidden>🧭</span>
        <span className="hidden sm:inline">{label}</span>
      </button>
      {open && <GuidedTour steps={steps} onClose={fermer} />}
    </>
  );
}
