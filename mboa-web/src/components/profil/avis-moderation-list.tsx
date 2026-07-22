"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Dialog } from "@/components/ui/dialog";
import { StarIcon } from "@/components/ui/icons";
import type { AvisAModerer } from "@/lib/data/avis-moderation";

// Miroir de _approuver / _refuser (avis_moderation_screen.dart).
export function AvisModerationList({ avis: initial }: { avis: AvisAModerer[] }) {
  const [avis, setAvis] = useState(initial);
  const [confirmId, setConfirmId] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  async function approuver(id: string) {
    setBusyId(id);
    const supabase = createClient();
    const { error } = await supabase.from("avis").update({ valide: true }).eq("id", id);
    setBusyId(null);
    if (!error) setAvis((prev) => prev.filter((a) => a.id !== id));
  }

  async function refuser(id: string) {
    setBusyId(id);
    const supabase = createClient();
    const { error } = await supabase.from("avis").delete().eq("id", id);
    setBusyId(null);
    setConfirmId(null);
    if (!error) setAvis((prev) => prev.filter((a) => a.id !== id));
  }

  if (avis.length === 0) {
    return (
      <div className="flex flex-col items-center px-8 py-20 text-center">
        <span className="text-5xl" aria-hidden>
          ✅
        </span>
        <p className="mt-4 text-base font-bold text-mboa-text">Rien à modérer</p>
        <p className="mt-2 max-w-xs text-sm text-mboa-text-muted">
          Les nouveaux avis sur vos annonces apparaîtront ici.
        </p>
      </div>
    );
  }

  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-2.5 px-4 pb-10">
      {avis.map((a) => (
        <div key={a.id} className="rounded-mboa-md bg-mboa-card p-3.5 shadow-sm">
          <div className="flex items-center gap-2">
            <p className="flex-1 text-[13px] font-bold text-mboa-text">{a.auteurNom}</p>
            <div className="flex items-center gap-0.5">
              {Array.from({ length: 5 }, (_, i) => (
                <StarIcon
                  key={i}
                  className={`h-3.5 w-3.5 ${i < a.note ? "text-mboa-boost" : "text-mboa-border"}`}
                />
              ))}
            </div>
          </div>
          {a.titreAnnonce && (
            <p className="mt-0.5 text-xs text-mboa-text-muted">à propos de « {a.titreAnnonce} »</p>
          )}
          {a.commentaire && (
            <p className="mt-2 text-sm leading-relaxed text-mboa-text">{a.commentaire}</p>
          )}
          <div className="mt-2.5 flex gap-2.5">
            <button
              type="button"
              onClick={() => setConfirmId(a.id)}
              disabled={busyId === a.id}
              className="flex-1 rounded-mboa-md border border-mboa-danger py-2.5 text-sm font-semibold text-mboa-danger disabled:opacity-60"
            >
              Refuser
            </button>
            <button
              type="button"
              onClick={() => approuver(a.id)}
              disabled={busyId === a.id}
              className="flex-1 rounded-mboa-md bg-mboa-verified py-2.5 text-sm font-semibold text-white disabled:opacity-60"
            >
              Approuver
            </button>
          </div>
        </div>
      ))}

      <Dialog open={confirmId !== null} onClose={() => setConfirmId(null)}>
        <h2 className="text-base font-bold text-mboa-text">Refuser cet avis ?</h2>
        <p className="mt-2 text-sm text-mboa-text-muted">
          L&apos;avis sera supprimé et ne sera jamais publié. La note déjà comptée dans votre score
          sera retirée.
        </p>
        <div className="mt-5 flex justify-end gap-3">
          <button
            type="button"
            onClick={() => setConfirmId(null)}
            className="rounded-mboa-md px-4 py-2 text-sm font-semibold text-mboa-text-muted"
          >
            Annuler
          </button>
          <button
            type="button"
            onClick={() => confirmId && refuser(confirmId)}
            className="rounded-mboa-md bg-mboa-danger px-4 py-2 text-sm font-semibold text-white"
          >
            Refuser
          </button>
        </div>
      </Dialog>
    </div>
  );
}
