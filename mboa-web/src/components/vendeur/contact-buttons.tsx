"use client";

import Link from "next/link";
import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

// Miroir de _appeler / _envoyerMessage dans profil_vendeur_screen.dart —
// le chat web n'existe pas encore, donc "Message" redirige vers la
// connexion (visiteur) ou explique que la messagerie est mobile-only.
export function ContactButtons({
  vendeurId,
  isLoggedIn,
  isSelf,
}: {
  vendeurId: string;
  isLoggedIn: boolean;
  isSelf: boolean;
}) {
  const [error, setError] = useState<string | null>(null);

  if (isSelf) return null;

  async function handleAppeler() {
    const supabase = createClient();
    const { data } = await supabase
      .from("users")
      .select("telephone")
      .eq("id", vendeurId)
      .single();

    const tel = data?.telephone as string | undefined;
    if (!tel) {
      setError("Numéro non renseigné par ce contributeur");
      return;
    }
    window.location.assign(`tel:${tel}`);
  }

  return (
    <div>
      {error && (
        <p className="mb-2 rounded-mboa-md bg-white/15 px-3 py-2 text-xs text-white">
          {error}
        </p>
      )}
      <div className="flex gap-3">
        <button
          onClick={handleAppeler}
          className="flex-1 rounded-mboa-lg border border-white/40 py-2.5 text-sm font-bold text-white"
        >
          📞 Appeler
        </button>
        {isLoggedIn ? (
          <button
            onClick={() => setError("La messagerie web arrive bientôt — utilise l'app mobile pour l'instant.")}
            className="flex-1 rounded-mboa-lg bg-white py-2.5 text-sm font-bold text-mboa-primary"
          >
            💬 Message
          </button>
        ) : (
          <Link
            href="/login"
            className="flex-1 rounded-mboa-lg bg-white py-2.5 text-center text-sm font-bold text-mboa-primary"
          >
            💬 Message
          </Link>
        )}
      </div>
    </div>
  );
}
