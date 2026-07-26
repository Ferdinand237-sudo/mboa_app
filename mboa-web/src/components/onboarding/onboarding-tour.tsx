"use client";

import { useCallback, useEffect, useLayoutEffect, useRef, useState } from "react";
import { usePathname } from "next/navigation";

const SEEN_KEY = "mboa_tour_seen";

type TourStep = {
  target: string;
  title: string;
  body: string;
};

// Chaque target correspond à un attribut data-tour posé sur l'élément réel
// (header-client.tsx, hero-header.tsx, category-cards.tsx). Certains onglets
// existent en double dans le DOM (nav desktop + menu mobile) : cibleVisible
// prend celui qui est réellement affiché selon la largeur d'écran.
const STEPS: TourStep[] = [
  {
    target: "logo",
    title: "Bienvenue sur Mboa 👋",
    body: "Ton premier ami dans une nouvelle ville. Fais un tour rapide pour découvrir comment ça marche, ça prend 30 secondes.",
  },
  {
    target: "recherche",
    title: "🔍 Cherche un logement",
    body: "Tape ce que tu cherches — chambre, studio, meublé — pour lancer une recherche en un instant.",
  },
  {
    target: "nav-logements",
    title: "🏠 Logement",
    body: "Trouve un logement avant même d'arriver à Sangmelima : photos, prix, commerces et équipements autour.",
  },
  {
    target: "nav-marketplace",
    title: "🛒 Market",
    body: "Achète ou vends du matériel entre étudiants : lits, bureaux, livres, électroménager...",
  },
  {
    target: "cat-carte",
    title: "🗺️ Carte",
    body: "Repère les logements, le campus, l'hôpital et le marché directement sur la carte.",
  },
  {
    target: "nav-chat",
    title: "💬 Chat",
    body: "Discute en direct avec les propriétaires et les vendeurs, dès que tu as un compte.",
  },
  {
    target: "register",
    title: "Crée ton compte",
    body: "Inscris-toi gratuitement pour débloquer le détail des annonces, le chat et les avis. On y va ?",
  },
];

function attendre(ms: number) {
  return new Promise<void>((resolve) => setTimeout(resolve, ms));
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

// Guide de prise en main pour les nouveaux visiteurs non connectés : une
// bulle pointe successivement vers la recherche, les onglets clés et
// l'inscription, avec Suivant / Précédent / Passer. Limité au visiteur
// anonyme (voir CLAUDE.md, "Visiteur Non Inscrit") : les navigations
// vendeur/admin/ambassadeur sont trop différentes pour une liste d'étapes
// générique, et l'objectif ici est l'accueil des tout nouveaux arrivants.
export function OnboardingTour({ anonyme }: { anonyme: boolean }) {
  const pathname = usePathname();
  const [actif, setActif] = useState(false);
  const [index, setIndex] = useState(0);
  const [rect, setRect] = useState<DOMRect | null>(null);
  const menuOuvertParLeTour = useRef(false);

  const fermerMenuSiOuvertParLeTour = useCallback(async () => {
    if (!menuOuvertParLeTour.current) return;
    document.querySelector<HTMLElement>("[data-tour-menu-toggle]")?.click();
    menuOuvertParLeTour.current = false;
    await attendre(80);
  }, []);

  // Lancement automatique une seule fois, uniquement sur l'accueil (seule
  // page qui contient tous les éléments ciblés : recherche, catégories...).
  useEffect(() => {
    if (!anonyme || pathname !== "/") return;
    if (localStorage.getItem(SEEN_KEY) === "1") return;
    const t = setTimeout(() => setActif(true), 900);
    return () => clearTimeout(t);
  }, [anonyme, pathname]);

  // Fonction async déclarée à l'intérieur de l'effet (et non via useCallback
  // référencé de l'extérieur) : c'est le seul moyen que le linter accepte
  // pour une mesure DOM asynchrone qui se termine par un setState, cf.
  // react.dev/link/hooks-data-fetching.
  useEffect(() => {
    if (!actif) return;
    let annule = false;
    async function positionner() {
      let el = cibleVisible(STEPS[index].target);
      if (!el) {
        // Sur mobile, l'onglet visé est peut-être caché dans le menu
        // hamburger (rendu uniquement quand il est ouvert) : on l'ouvre
        // nous-mêmes le temps de cette étape.
        const toggle = document.querySelector<HTMLElement>("[data-tour-menu-toggle]");
        if (toggle) {
          toggle.click();
          menuOuvertParLeTour.current = true;
          await attendre(80);
          el = cibleVisible(STEPS[index].target);
        }
      } else if (!dansMenuMobile(el)) {
        // Trouvé sans avoir besoin du menu (desktop, ou élément hors menu) :
        // si une étape précédente l'avait ouvert, on peut le refermer.
        // Si l'élément trouvé est lui-même DANS le menu encore ouvert
        // (deux étapes mobiles consécutives), on le laisse tel quel.
        await fermerMenuSiOuvertParLeTour();
      }
      if (annule) return;
      if (!el) {
        setRect(null);
        return;
      }
      el.scrollIntoView({ behavior: "smooth", block: "center" });
      await attendre(220);
      if (!annule) setRect(el.getBoundingClientRect());
    }
    positionner();
    return () => {
      annule = true;
    };
  }, [actif, index, fermerMenuSiOuvertParLeTour]);

  // Recalcule la position si la fenêtre est redimensionnée pendant la visite.
  useEffect(() => {
    if (!actif) return;
    function recalc() {
      const el = cibleVisible(STEPS[index].target);
      if (el) setRect(el.getBoundingClientRect());
    }
    window.addEventListener("resize", recalc);
    return () => window.removeEventListener("resize", recalc);
  }, [actif, index]);

  function terminer() {
    localStorage.setItem(SEEN_KEY, "1");
    fermerMenuSiOuvertParLeTour();
    setActif(false);
    setIndex(0);
  }

  function suivant() {
    if (index === STEPS.length - 1) {
      terminer();
      return;
    }
    setIndex((i) => i + 1);
  }

  function precedent() {
    setIndex((i) => Math.max(0, i - 1));
  }

  function relancer() {
    setIndex(0);
    setActif(true);
  }

  if (!anonyme || pathname !== "/") return null;

  return (
    <>
      {!actif && (
        <button
          type="button"
          onClick={relancer}
          className="fixed bottom-24 right-4 z-40 flex h-12 w-12 items-center justify-center rounded-full bg-mboa-primary text-xl text-white shadow-lg md:bottom-6"
          aria-label="Revoir la visite guidée"
          title="Revoir la visite guidée"
        >
          🧭
        </button>
      )}
      {actif && rect && (
        <TourBulle
          rect={rect}
          index={index}
          total={STEPS.length}
          title={STEPS[index].title}
          body={STEPS[index].body}
          onSuivant={suivant}
          onPrecedent={index > 0 ? precedent : undefined}
          onPasser={terminer}
        />
      )}
    </>
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
          <button type="button" onClick={onPasser} className="mt-2 w-full text-center text-[11px] font-semibold text-mboa-text-muted">
            Passer la visite
          </button>
        )}
      </div>
    </>
  );
}
