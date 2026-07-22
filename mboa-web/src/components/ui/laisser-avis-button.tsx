"use client";

import { useState } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";

// Miroir de _laisserAvis (logement_detail_screen.dart / article_detail_screen.dart).
export function LaisserAvisButton({
  cibleId,
  annonceId,
  isLoggedIn,
}: {
  cibleId: string;
  annonceId: string;
  isLoggedIn: boolean;
}) {
  const [open, setOpen] = useState(false);
  const [note, setNote] = useState(5);
  const [commentaire, setCommentaire] = useState("");
  const [sending, setSending] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  if (!isLoggedIn) {
    return (
      <Link href="/login" className="text-xs font-bold text-mboa-primary">
        Laisser un avis
      </Link>
    );
  }

  async function envoyer() {
    setSending(true);
    const supabase = createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user || user.id === cibleId) {
      setSending(false);
      setOpen(false);
      return;
    }

    const { error } = await supabase.from("avis").insert({
      auteur_id: user.id,
      cible_id: cibleId,
      annonce_id: annonceId,
      note,
      commentaire: commentaire.trim(),
      valide: false,
    });

    setSending(false);
    setOpen(false);
    setMessage(
      error
        ? "Erreur lors de l'envoi de l'avis"
        : "Merci ! Ton avis sera visible dès validation (ou sous 72h).",
    );
  }

  return (
    <div>
      <button
        onClick={() => setOpen(true)}
        className="text-xs font-bold text-mboa-primary"
      >
        Laisser un avis
      </button>

      {message && <p className="mt-1 text-xs text-mboa-text-muted">{message}</p>}

      {open && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-sm rounded-mboa-xl bg-mboa-card p-5">
            <h3 className="text-base font-extrabold text-mboa-text">
              ⭐ Laisser un avis
            </h3>
            <p className="mt-1 text-xs text-mboa-text-muted">
              Ton expérience avec cette annonce
            </p>
            <div className="mt-3 flex justify-center gap-1.5">
              {[1, 2, 3, 4, 5].map((n) => (
                <button
                  key={n}
                  onClick={() => setNote(n)}
                  className="text-2xl"
                  aria-label={`${n} étoiles`}
                >
                  {n <= note ? "★" : "☆"}
                </button>
              ))}
            </div>
            <textarea
              value={commentaire}
              onChange={(e) => setCommentaire(e.target.value)}
              placeholder="Ton commentaire (optionnel)"
              rows={3}
              className="mt-3 w-full rounded-mboa-md border border-mboa-border px-3 py-2 text-sm outline-none focus:border-mboa-primary"
            />
            <div className="mt-4 flex justify-end gap-3">
              <button
                onClick={() => setOpen(false)}
                className="px-3 py-2 text-sm font-semibold text-mboa-text-muted"
              >
                Annuler
              </button>
              <button
                onClick={envoyer}
                disabled={sending}
                className="rounded-mboa-md bg-mboa-primary px-4 py-2 text-sm font-bold text-white disabled:opacity-60"
              >
                {sending ? "Envoi..." : "Envoyer"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
