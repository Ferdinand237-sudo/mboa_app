"use client";

import Image from "next/image";
import { useEffect, useState, useSyncExternalStore } from "react";

const DISMISS_KEY = "mboa_install_prompt_dismiss";
const noSubscribe = () => () => {};

type BeforeInstallPromptEvent = Event & {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: "accepted" | "dismissed" }>;
};

function estIOS(): boolean {
  return /iphone|ipad|ipod/i.test(window.navigator.userAgent);
}

function estEligible(): boolean {
  return localStorage.getItem(DISMISS_KEY) !== "1" && !window.matchMedia("(display-mode: standalone)").matches;
}

// Bannière "Installer Mboa" : sur Android/Chrome, capture l'évènement natif
// beforeinstallprompt (sinon aucun bouton n'apparaît jamais par défaut) ;
// sur iOS/Safari cet évènement n'existe pas, on affiche donc l'instruction
// manuelle (Partager -> Sur l'écran d'accueil). Une fois installée ou
// masquée, l'icône ajoutée affiche déjà le logo Mboa avec "Mboa" en dessous
// (voir manifest.ts / appleWebApp), comme une vraie app.
//
// eligible/isIOS lisent des API navigateur (localStorage, matchMedia,
// userAgent) absentes côté serveur : useSyncExternalStore fournit le bon
// instantané côté client après hydratation sans provoquer de setState direct
// dans un effet (règle react-hooks/set-state-in-effect) ni de mismatch SSR.
export function InstallPrompt() {
  const eligible = useSyncExternalStore(noSubscribe, estEligible, () => false);
  const isIOS = useSyncExternalStore(noSubscribe, estIOS, () => false);
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null);
  const [manuallyDismissed, setManuallyDismissed] = useState(false);

  useEffect(() => {
    function onBeforeInstallPrompt(e: Event) {
      e.preventDefault();
      setDeferredPrompt(e as BeforeInstallPromptEvent);
    }
    window.addEventListener("beforeinstallprompt", onBeforeInstallPrompt);
    return () => window.removeEventListener("beforeinstallprompt", onBeforeInstallPrompt);
  }, []);

  function fermer() {
    localStorage.setItem(DISMISS_KEY, "1");
    setManuallyDismissed(true);
  }

  async function installer() {
    if (!deferredPrompt) return;
    await deferredPrompt.prompt();
    await deferredPrompt.userChoice;
    setDeferredPrompt(null);
    fermer();
  }

  if (!eligible || manuallyDismissed || (!deferredPrompt && !isIOS)) return null;

  return (
    <div className="fixed inset-x-0 bottom-0 z-50 border-t border-mboa-border bg-mboa-card px-4 py-3 shadow-[0_-4px_16px_rgba(0,0,0,0.08)] sm:bottom-4 sm:left-1/2 sm:right-auto sm:w-[420px] sm:-translate-x-1/2 sm:rounded-mboa-lg sm:border">
      <div className="mx-auto flex max-w-2xl items-center gap-3 sm:mx-0">
        <Image src="/logo-mboa.png" alt="Mboa" width={44} height={44} className="h-11 w-11 shrink-0 rounded-xl object-contain" />
        <div className="min-w-0 flex-1">
          <p className="text-sm font-bold text-mboa-text">Installer Mboa</p>
          <p className="mt-0.5 text-xs leading-relaxed text-mboa-text-muted">
            {isIOS
              ? "Appuie sur Partager puis « Sur l'écran d'accueil » pour y accéder en un tap."
              : "Ajoute le raccourci sur ton téléphone pour y accéder en un tap, comme une vraie app."}
          </p>
        </div>
        <div className="flex shrink-0 flex-col items-end gap-1.5">
          {!isIOS && (
            <button
              type="button"
              onClick={installer}
              className="rounded-mboa-md bg-mboa-primary px-3.5 py-2 text-xs font-bold text-white"
            >
              Installer
            </button>
          )}
          <button
            type="button"
            onClick={fermer}
            aria-label="Fermer"
            className="text-xs font-semibold text-mboa-text-muted"
          >
            {isIOS ? "Fermer" : "Plus tard"}
          </button>
        </div>
      </div>
    </div>
  );
}
