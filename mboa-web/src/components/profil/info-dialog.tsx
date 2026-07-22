"use client";

import { Dialog } from "@/components/ui/dialog";

// Miroir de _ouvrirConfidentialite / _ouvrirAideSupport (profil_screen.dart) :
// dialogue d'info générique titre + texte + bouton unique.
export function InfoDialog({
  open,
  onClose,
  title,
  body,
  closeLabel = "Fermer",
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  body: string;
  closeLabel?: string;
}) {
  return (
    <Dialog open={open} onClose={onClose}>
      <h3 className="text-base font-bold text-mboa-text">{title}</h3>
      <p className="mt-3 text-sm leading-relaxed text-mboa-text-muted">{body}</p>
      <div className="mt-6 flex justify-end">
        <button onClick={onClose} className="px-3 py-2 text-sm font-semibold text-mboa-primary">
          {closeLabel}
        </button>
      </div>
    </Dialog>
  );
}
