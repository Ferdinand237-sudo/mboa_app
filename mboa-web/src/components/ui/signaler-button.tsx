"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

const RAISONS = [
  "Fausse annonce",
  "Arnaque",
  "Prix incorrect",
  "Contenu inapproprié",
  "Annonce dupliquée",
];

// Miroir de _showSignalementDialog dans les écrans détail.
export function SignalerButton({ annonceId }: { annonceId: string }) {
  const [open, setOpen] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  async function signaler(raison: string) {
    setOpen(false);
    const supabase = createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      window.location.assign("/login");
      return;
    }

    await supabase.from("signalements").insert({
      signaleur_id: user.id,
      cible_type: "annonce",
      cible_id: annonceId,
      raison,
    });
    setMessage("Signalement envoyé. Merci !");
  }

  return (
    <div className="text-center">
      <button
        onClick={() => setOpen(true)}
        className="inline-flex items-center gap-1.5 text-xs text-mboa-danger"
      >
        🚩 Signaler cette annonce
      </button>
      {message && <p className="mt-2 text-xs text-mboa-text-muted">{message}</p>}

      {open && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-sm rounded-mboa-xl bg-mboa-card p-5 text-left">
            <h3 className="text-base font-bold text-mboa-text">
              🚨 Signaler cette annonce
            </h3>
            <div className="mt-3">
              {RAISONS.map((r) => (
                <button
                  key={r}
                  onClick={() => signaler(r)}
                  className="block w-full border-b border-mboa-border py-3 text-left text-sm text-mboa-text last:border-none"
                >
                  {r}
                </button>
              ))}
            </div>
            <button
              onClick={() => setOpen(false)}
              className="mt-3 w-full py-2 text-sm font-semibold text-mboa-text-muted"
            >
              Annuler
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
