"use client";

import { useState } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import { Photo } from "@/components/ui/photo";
import { formatPrix } from "@/lib/utils/format";
import type { FavoriItem } from "@/lib/data/favoris-list";

// Miroir de _buildFavoriCard (favoris_screen.dart) : suppression optimiste
// du favori au clic sur le cœur.
export function FavoriCard({ item }: { item: FavoriItem }) {
  const [removed, setRemoved] = useState(false);

  async function retirer() {
    setRemoved(true);
    const supabase = createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return;
    const column = item.type === "logement" ? "logement_id" : "article_id";
    await supabase.from("favoris").delete().eq("user_id", user.id).eq(column, item.id);
  }

  if (removed) return null;

  const href = item.type === "logement" ? `/logements/${item.id}` : `/marketplace/${item.id}`;
  const emoji = item.type === "logement" ? "🏠" : "📦";

  return (
    <div className="flex overflow-hidden rounded-mboa-lg bg-mboa-card shadow-sm">
      <Link href={href} className="flex flex-1 items-stretch">
        <div className="relative h-[100px] w-[100px] shrink-0 bg-gradient-to-br from-mboa-primary to-mboa-primary-light">
          <Photo src={item.photos[0]} alt={item.titre} />
        </div>
        <div className="min-w-0 flex-1 p-3">
          <p className="truncate text-[13px] font-bold text-mboa-text">{item.titre}</p>
          <p className="mt-1 text-[13px] font-extrabold text-mboa-primary">{formatPrix(item.prix)}</p>
          <p className="mt-1 flex items-center gap-1 truncate text-xs text-mboa-text-muted">
            📍 {item.sousTitre}
            {item.verified && <span className="text-[11px]">✅</span>}
          </p>
        </div>
      </Link>
      <button
        onClick={retirer}
        aria-label="Retirer des favoris"
        className="mr-2 flex h-8 w-8 shrink-0 items-center justify-center self-center rounded-full bg-mboa-danger/10 text-mboa-danger"
      >
        ♥
      </button>
      <span className="sr-only">{emoji}</span>
    </div>
  );
}
