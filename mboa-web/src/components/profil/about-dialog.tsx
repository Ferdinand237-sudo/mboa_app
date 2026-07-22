"use client";

import { Dialog } from "@/components/ui/dialog";
import { APP_NAME, APP_SLOGAN } from "@/lib/constants";

const APP_VERSION = "1.0.0";

// Miroir de _ouvrirAPropos / showAboutDialog (profil_screen.dart).
export function AboutDialog({ open, onClose }: { open: boolean; onClose: () => void }) {
  return (
    <Dialog open={open} onClose={onClose}>
      <div className="flex flex-col items-center text-center">
        <span className="flex h-12 w-12 items-center justify-center rounded-xl bg-mboa-primary text-2xl">
          🏘
        </span>
        <h3 className="mt-3 text-base font-bold text-mboa-text">
          {APP_NAME} <span className="text-mboa-text-muted">v{APP_VERSION}</span>
        </h3>
        <p className="mt-2 text-sm text-mboa-text-muted">{APP_SLOGAN}</p>
      </div>
      <div className="mt-6 flex justify-end">
        <button onClick={onClose} className="px-3 py-2 text-sm font-semibold text-mboa-primary">
          Fermer
        </button>
      </div>
    </Dialog>
  );
}
