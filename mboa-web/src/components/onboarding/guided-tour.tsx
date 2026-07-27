"use client";

import { useEffect, useLayoutEffect, useRef, useState } from "react";
import type { TourStep } from "@/components/onboarding/tours";

function attendre(ms: number) {
  return new Promise<void>((resolve) => setTimeout(resolve, ms));
}

// Attend la fin réelle du scroll déclenché par scrollIntoView avant de
// mesurer la cible, au lieu d'un délai fixe : sur mobile, les formulaires en
// une colonne demandent un scroll bien plus long qu'un délai qui suffit sur
// desktop (ex. position GPS/bouton Publier tout en bas), ce qui capturait la
// position en pleine animation et décalait durablement le halo par rapport
// au bouton réel. On considère le scroll terminé quand la position de la
// cible ne bouge plus entre deux mesures.
async function attendreScrollStable(el: HTMLElement, maxMs = 1200): Promise<DOMRect> {
  let precedent = el.getBoundingClientRect();
  const debut = Date.now();
  while (Date.now() - debut < maxMs) {
    await attendre(60);
    const actuel = el.getBoundingClientRect();
    if (Math.abs(actuel.top - precedent.top) < 0.5 && Math.abs(actuel.left - precedent.left) < 0.5) {
      return actuel;
    }
    precedent = actuel;
  }
  return el.getBoundingClientRect();
}

function cibleVisible(nom: string): HTMLElement | null {
  const elements = document.querySelectorAll<HTMLElement>(`[data-tour="${nom}"]`);
  for (const el of elements) {
    const rect = el.getBoundingClientRect();
    if (rect.width > 0 && rect.height > 0) return el;
  }
  return null;
}

function dansMenuMobile(el: HTMLElement): boolean {
  return el.closest("[data-tour-mobile-menu]") !== null;
}

// Moteur générique de visite guidée : une bulle pointe vers l'élément
// data-tour de chaque étape (halo + flèche), avec Suivant/Précédent/Passer.
// Monté/démonté par l'appelant (TourButton) plutôt que piloté par un prop
// "open" : ça réinitialise l'étape à 0 gratuitement à chaque ouverture, sans
// effet dédié à ce reset.
export function GuidedTour({ steps, onClose }: { steps: TourStep[]; onClose: () => void }) {
  const [index, setIndex] = useState(0);
  const [rect, setRect] = useState<DOMRect | null>(null);
  const menuOuvertParLeTour = useRef(false);

  // Fonction async déclarée à l'intérieur de l'effet (et non via useCallback
  // référencé de l'extérieur) : c'est le seul moyen que le linter accepte
  // pour une mesure DOM asynchrone qui se termine par un setState, cf.
  // react.dev/link/hooks-data-fetching.
  useEffect(() => {
    let annule = false;
    async function positionner() {
      const cible = steps[index].target;
      let el = cibleVisible(cible);
      if (!el) {
        // Sur mobile, l'onglet visé est peut-être caché dans le menu
        // hamburger (rendu uniquement quand il est ouvert) : on l'ouvre
        // nous-mêmes le temps de cette étape.
        const toggle = document.querySelector<HTMLElement>("[data-tour-menu-toggle]");
        if (toggle) {
          toggle.click();
          menuOuvertParLeTour.current = true;
          await attendre(80);
          el = cibleVisible(cible);
        }
      } else if (menuOuvertParLeTour.current && !dansMenuMobile(el)) {
        // Trouvé sans avoir besoin du menu (desktop, ou élément hors menu) :
        // si une étape précédente l'avait ouvert, on peut le refermer. Si
        // l'élément trouvé est lui-même DANS le menu encore ouvert (deux
        // étapes mobiles consécutives), on le laisse tel quel.
        document.querySelector<HTMLElement>("[data-tour-menu-toggle]")?.click();
        menuOuvertParLeTour.current = false;
        await attendre(80);
      }
      if (annule) return;
      if (!el) {
        // Cible absente pour ce rôle/ces permissions (onglet non affiché,
        // formulaire différent...) : on saute l'étape plutôt que de bloquer
        // la visite sur une bulle vide.
        if (index < steps.length - 1) {
          setIndex((i) => i + 1);
        } else {
          onClose();
        }
        return;
      }
      el.scrollIntoView({ behavior: "smooth", block: "center" });
      const rectStable = await attendreScrollStable(el);
      if (!annule) setRect(rectStable);
    }
    positionner();
    return () => {
      annule = true;
    };
  }, [index, steps, onClose]);

  // Recalcule la position si la fenêtre est redimensionnée, ou si la page
  // défile pendant la visite (le clic hors de la bulle ferme la visite, mais
  // un scroll tactile/molette passe au travers et doit garder le halo aligné
  // sur la cible réelle).
  useEffect(() => {
    function recalc() {
      const el = cibleVisible(steps[index].target);
      if (el) setRect(el.getBoundingClientRect());
    }
    window.addEventListener("resize", recalc);
    window.addEventListener("scroll", recalc, { passive: true, capture: true });
    return () => {
      window.removeEventListener("resize", recalc);
      window.removeEventListener("scroll", recalc, true);
    };
  }, [index, steps]);

  function fermer() {
    if (menuOuvertParLeTour.current) {
      document.querySelector<HTMLElement>("[data-tour-menu-toggle]")?.click();
      menuOuvertParLeTour.current = false;
    }
    onClose();
  }

  function suivant() {
    if (index === steps.length - 1) {
      fermer();
      return;
    }
    setIndex((i) => i + 1);
  }

  function precedent() {
    setIndex((i) => Math.max(0, i - 1));
  }

  if (!rect) return null;

  return (
    <TourBulle
      rect={rect}
      index={index}
      total={steps.length}
      title={steps[index].title}
      body={steps[index].body}
      onSuivant={suivant}
      onPrecedent={index > 0 ? precedent : undefined}
      onPasser={fermer}
    />
  );
}

function TourBulle({
  rect,
  index,
  total,
  title,
  body,
  onSuivant,
  onPrecedent,
  onPasser,
}: {
  rect: DOMRect;
  index: number;
  total: number;
  title: string;
  body: string;
  onSuivant: () => void;
  onPrecedent?: () => void;
  onPasser: () => void;
}) {
  const carteRef = useRef<HTMLDivElement>(null);
  const [style, setStyle] = useState<{ top: number; left: number; enBas: boolean; flecheLeft: number } | null>(null);

  useLayoutEffect(() => {
    const marge = 12;
    const carte = carteRef.current;
    const largeurCarte = carte?.offsetWidth ?? 300;
    const hauteurCarte = carte?.offsetHeight ?? 140;
    const enBas = window.innerHeight - rect.bottom > hauteurCarte + marge * 2 || rect.top < hauteurCarte + marge * 2;
    const top = enBas ? rect.bottom + marge : rect.top - hauteurCarte - marge;
    const centreCible = rect.left + rect.width / 2;
    let left = centreCible - largeurCarte / 2;
    left = Math.max(marge, Math.min(left, window.innerWidth - largeurCarte - marge));
    const flecheLeft = Math.max(16, Math.min(centreCible - left, largeurCarte - 16));
    setStyle({ top, left, enBas, flecheLeft });
  }, [rect]);

  const padding = 6;

  return (
    <>
      {/* Halo qui assombrit toute la page sauf un rectangle autour de la
          cible : un seul élément dimensionné sur la cible, avec un
          box-shadow géant, plutôt que 4 bandeaux à recalculer séparément. */}
      <div
        className="fixed z-[80] rounded-xl ring-2 ring-white/90 transition-all duration-200"
        style={{
          top: rect.top - padding,
          left: rect.left - padding,
          width: rect.width + padding * 2,
          height: rect.height + padding * 2,
          boxShadow: "0 0 0 9999px rgba(15, 23, 42, 0.6)",
        }}
      />
      {/* Capte les clics sur le reste de la page pour forcer l'usage des
          boutons Suivant/Passer, sans bloquer le halo au-dessus. */}
      <div className="fixed inset-0 z-[79]" onClick={onPasser} />

      <div
        ref={carteRef}
        className="fixed z-[81] w-[calc(100vw-2rem)] max-w-[300px] rounded-mboa-lg border border-mboa-border bg-white p-4 shadow-2xl"
        style={style ? { top: style.top, left: style.left } : { top: -9999, left: -9999 }}
      >
        {style && (
          <span
            className="absolute h-3 w-3 rotate-45 border border-mboa-border bg-white"
            style={
              style.enBas
                ? { top: -7, left: style.flecheLeft, borderRight: "none", borderBottom: "none" }
                : { bottom: -7, left: style.flecheLeft, borderLeft: "none", borderTop: "none" }
            }
          />
        )}

        <div className="flex items-start justify-between gap-2">
          <p className="text-sm font-extrabold text-mboa-text">{title}</p>
          <button
            type="button"
            onClick={onPasser}
            aria-label="Fermer la visite"
            className="shrink-0 text-mboa-text-muted"
          >
            ✕
          </button>
        </div>
        <p className="mt-1.5 text-xs leading-relaxed text-mboa-text-muted">{body}</p>

        <div className="mt-3.5 flex items-center justify-between">
          <div className="flex gap-1">
            {Array.from({ length: total }).map((_, i) => (
              <span
                key={i}
                className={`h-1.5 w-1.5 rounded-full ${i === index ? "bg-mboa-primary" : "bg-mboa-border"}`}
              />
            ))}
          </div>
          <div className="flex items-center gap-3">
            {onPrecedent && (
              <button type="button" onClick={onPrecedent} className="text-xs font-semibold text-mboa-text-muted">
                Précédent
              </button>
            )}
            <button
              type="button"
              onClick={onSuivant}
              className="rounded-mboa-md bg-mboa-primary px-3.5 py-1.5 text-xs font-bold text-white"
            >
              {index === total - 1 ? "Terminer" : "Suivant"}
            </button>
          </div>
        </div>
        {index < total - 1 && (
          <button
            type="button"
            onClick={onPasser}
            className="mt-2 w-full text-center text-[11px] font-semibold text-mboa-text-muted"
          >
            Passer la visite
          </button>
        )}
      </div>
    </>
  );
}
