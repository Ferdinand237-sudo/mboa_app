"use client";

import { Dialog } from "@/components/ui/dialog";

export function ConfirmDialog({
  open,
  onClose,
  title,
  body,
  confirmLabel,
  confirmClass = "bg-mboa-danger",
  onConfirm,
  busy,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  body: string;
  confirmLabel: string;
  confirmClass?: string;
  onConfirm: () => void;
  busy?: boolean;
}) {
  return (
    <Dialog open={open} onClose={onClose}>
      <h2 className="text-base font-bold text-mboa-text">{title}</h2>
      <p className="mt-2 text-sm text-mboa-text-muted">{body}</p>
      <div className="mt-5 flex justify-end gap-3">
        <button
          type="button"
          onClick={onClose}
          className="rounded-mboa-md px-4 py-2 text-sm font-semibold text-mboa-text-muted"
        >
          Annuler
        </button>
        <button
          type="button"
          onClick={onConfirm}
          disabled={busy}
          className={`rounded-mboa-md px-4 py-2 text-sm font-semibold text-white disabled:opacity-60 ${confirmClass}`}
        >
          {confirmLabel}
        </button>
      </div>
    </Dialog>
  );
}
