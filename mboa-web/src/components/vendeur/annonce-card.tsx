"use client";

import { useState } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import { Photo } from "@/components/ui/photo";
import { Dialog } from "@/components/ui/dialog";
import { EditIcon, TrashIcon } from "@/components/ui/icons";
import { formatPrix } from "@/lib/utils/format";
import type { MonLogement, MonArticle } from "@/lib/data/vendeur-annonces";

const MODERATION_LABEL: Record<string, string> = {
  en_attente: "Analyse en cours",
  a_verifier: "En vérification",
  bloque: "Bloqué",
};
const MODERATION_COLOR: Record<string, string> = {
  a_verifier: "bg-mboa-boost/10 text-mboa-boost",
  bloque: "bg-mboa-danger/10 text-mboa-danger",
  en_attente: "bg-mboa-text-muted/10 text-mboa-text-muted",
};

// Miroir de _buildCard (gestion_screen.dart) : modifier / suspendre-réactiver
// / supprimer avec confirmation.
export function AnnonceCard({
  item,
  table,
  detailHref,
  editHref,
  onRemoved,
}: {
  item: MonLogement | MonArticle;
  table: "logements" | "articles";
  detailHref: string;
  editHref: string;
  onRemoved: () => void;
}) {
  const [statut, setStatut] = useState(item.statut);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const estDisponible = statut === "disponible";

  async function toggleStatut() {
    const nouveau = estDisponible ? "suspendu" : "disponible";
    setBusy(true);
    const supabase = createClient();
    const { error } = await supabase.from(table).update({ statut: nouveau }).eq("id", item.id);
    setBusy(false);
    if (!error) setStatut(nouveau);
  }

  async function supprimer() {
    setBusy(true);
    const supabase = createClient();
    const { error } = await supabase.from(table).delete().eq("id", item.id);
    setBusy(false);
    setConfirmOpen(false);
    if (!error) onRemoved();
  }

  return (
    <div className="rounded-mboa-lg bg-mboa-card p-3 shadow-sm">
      <Link href={detailHref} className="flex items-center gap-3">
        <div className="relative h-16 w-16 shrink-0 overflow-hidden rounded-[10px] bg-gradient-to-br from-mboa-primary to-mboa-primary-light">
          <Photo src={item.photos[0]} alt={item.titre} />
        </div>
        <div className="min-w-0 flex-1">
          <p className="truncate text-[13px] font-bold text-mboa-text">{item.titre}</p>
          <p className="mt-0.5 text-[13px] font-extrabold text-mboa-primary">{formatPrix(item.prix)}</p>
          <div className="mt-1 flex flex-wrap gap-1.5">
            <span
              className={`rounded-full px-2 py-0.5 text-[10px] font-bold ${
                estDisponible ? "bg-mboa-verified/10 text-mboa-verified" : "bg-mboa-text-muted/10 text-mboa-text-muted"
              }`}
            >
              {estDisponible ? "Disponible" : "Suspendu"}
            </span>
            {item.statutModeration !== "publie" && (
              <span
                className={`rounded-full px-2 py-0.5 text-[10px] font-bold ${MODERATION_COLOR[item.statutModeration] ?? ""}`}
              >
                {MODERATION_LABEL[item.statutModeration] ?? ""}
              </span>
            )}
          </div>
        </div>
      </Link>
      <div className="mt-2.5 flex divide-x divide-mboa-border border-t border-mboa-border pt-2">
        <Link
          href={editHref}
          className="flex flex-1 items-center justify-center gap-1 py-2 text-[11.5px] font-semibold text-mboa-primary"
        >
          <EditIcon className="h-3.5 w-3.5" /> Modifier
        </Link>
        <button
          type="button"
          onClick={toggleStatut}
          disabled={busy}
          className="flex flex-1 items-center justify-center gap-1 py-2 text-[11.5px] font-semibold text-mboa-boost disabled:opacity-60"
        >
          {estDisponible ? "⏸" : "▶"} {estDisponible ? "Suspendre" : "Réactiver"}
        </button>
        <button
          type="button"
          onClick={() => setConfirmOpen(true)}
          className="flex flex-1 items-center justify-center gap-1 py-2 text-[11.5px] font-semibold text-mboa-danger"
        >
          <TrashIcon className="h-3.5 w-3.5" /> Supprimer
        </button>
      </div>

      <Dialog open={confirmOpen} onClose={() => setConfirmOpen(false)}>
        <h2 className="text-base font-bold text-mboa-text">Supprimer cette annonce ?</h2>
        <p className="mt-2 text-sm text-mboa-text-muted">Cette action est définitive.</p>
        <div className="mt-5 flex justify-end gap-3">
          <button
            type="button"
            onClick={() => setConfirmOpen(false)}
            className="rounded-mboa-md px-4 py-2 text-sm font-semibold text-mboa-text-muted"
          >
            Annuler
          </button>
          <button
            type="button"
            onClick={supprimer}
            disabled={busy}
            className="rounded-mboa-md bg-mboa-danger px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
          >
            Supprimer
          </button>
        </div>
      </Dialog>
    </div>
  );
}
