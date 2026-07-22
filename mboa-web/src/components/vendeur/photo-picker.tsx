"use client";

import { useRef } from "react";
import Image from "next/image";
import { Photo } from "@/components/ui/photo";

export type PhotoItem = { kind: "existing"; url: string } | { kind: "new"; preview: string };

const VARIANTS = {
  primary: {
    border: "border-mboa-primary/30",
    bg: "bg-mboa-primary/6",
    text: "text-mboa-primary",
  },
  secondary: {
    border: "border-mboa-secondary/30",
    bg: "bg-mboa-secondary/6",
    text: "text-mboa-secondary",
  },
};

// Miroir des grilles photos horizontales (publier_screen.dart, edit_logement_screen.dart,
// edit_article_screen.dart) : photos existantes (URL distante) + nouvelles (aperçu local
// via URL.createObjectURL), bouton d'ajout tant que max n'est pas atteint.
export function PhotoPicker({
  photos,
  max,
  variant,
  onAdd,
  onRemove,
}: {
  photos: PhotoItem[];
  max: number;
  variant: "primary" | "secondary";
  onAdd: (file: File) => void;
  onRemove: (index: number) => void;
}) {
  const inputRef = useRef<HTMLInputElement>(null);
  const c = VARIANTS[variant];

  return (
    <div className="flex gap-2.5 overflow-x-auto pb-1">
      {photos.map((p, i) => (
        <div key={i} className="relative h-[100px] w-[100px] shrink-0 overflow-hidden rounded-xl bg-mboa-background">
          {p.kind === "existing" ? (
            <Photo src={p.url} alt="" />
          ) : (
            <Image src={p.preview} alt="" fill unoptimized className="object-cover" />
          )}
          <button
            type="button"
            onClick={() => onRemove(i)}
            aria-label="Supprimer la photo"
            className="absolute right-1 top-1 flex h-[22px] w-[22px] items-center justify-center rounded-full bg-mboa-danger text-white"
          >
            ✕
          </button>
        </div>
      ))}
      {photos.length < max && (
        <button
          type="button"
          onClick={() => inputRef.current?.click()}
          className={`flex h-[100px] w-[100px] shrink-0 flex-col items-center justify-center gap-1.5 rounded-xl border-[1.5px] ${c.border} ${c.bg} ${c.text}`}
        >
          <span className="text-2xl" aria-hidden>
            📷
          </span>
          <span className="text-[11px] font-semibold">{photos.length === 0 ? "Ajouter" : "+ Photo"}</span>
        </button>
      )}
      <input
        ref={inputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={(e) => {
          const file = e.target.files?.[0];
          if (file) onAdd(file);
          e.target.value = "";
        }}
      />
    </div>
  );
}
