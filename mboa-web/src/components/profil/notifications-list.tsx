"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import type { NotificationRow } from "@/lib/data/notifications";

const ICONES: Record<NotificationRow["type"], string> = {
  message: "💬",
  avis: "⭐",
  annonce: "🏘",
};

// Miroir de _formatDate (notifications_screen.dart).
function formatDate(dateStr: string): string {
  const date = new Date(dateStr);
  const diffMs = Date.now() - date.getTime();
  const minutes = Math.floor(diffMs / 60000);
  const hours = Math.floor(diffMs / 3600000);
  const days = Math.floor(diffMs / 86400000);
  if (minutes < 60) return `Il y a ${minutes} min`;
  if (hours < 24) return `Il y a ${hours} h`;
  if (days < 7) return `Il y a ${days} j`;
  return date.toLocaleDateString("fr-FR");
}

export function NotificationsList({ notifications }: { notifications: NotificationRow[] }) {
  const [items, setItems] = useState(notifications);
  const router = useRouter();

  async function ouvrir(n: NotificationRow) {
    if (!n.lu) {
      const supabase = createClient();
      await supabase.from("notifications").update({ lu: true }).eq("id", n.id);
      setItems((prev) => prev.map((x) => (x.id === n.id ? { ...x, lu: true } : x)));
    }
    if (n.lien) router.push(n.lien);
  }

  if (items.length === 0) {
    return (
      <div className="flex flex-col items-center px-8 py-20 text-center">
        <span className="text-5xl" aria-hidden>
          🔕
        </span>
        <p className="mt-4 text-base font-bold text-mboa-text">Aucune notification</p>
        <p className="mt-2 max-w-xs text-sm text-mboa-text-muted">
          Tu seras notifié ici des nouveaux messages, avis et annonces correspondant à tes alertes.
        </p>
      </div>
    );
  }

  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-2 px-4 pb-10">
      {items.map((n) => (
        <button
          key={n.id}
          type="button"
          onClick={() => ouvrir(n)}
          className={`flex w-full items-center gap-3 rounded-mboa-md p-3.5 text-left shadow-sm ${
            n.lu ? "bg-mboa-card" : "bg-mboa-primary/6"
          }`}
        >
          <span
            className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl text-lg ${
              n.type === "message" ? "bg-mboa-primary/12" : n.type === "avis" ? "bg-mboa-boost/12" : "bg-mboa-secondary/12"
            }`}
          >
            {ICONES[n.type]}
          </span>
          <div className="min-w-0 flex-1">
            <p className={`text-[13px] ${n.lu ? "font-semibold text-mboa-text" : "font-bold text-mboa-text"}`}>{n.titre}</p>
            {n.corps && <p className="mt-0.5 truncate text-xs text-mboa-text-muted">{n.corps}</p>}
            <p className="mt-0.5 text-xs text-mboa-text-muted">{formatDate(n.createdAt)}</p>
          </div>
          {!n.lu && <span className="h-2 w-2 shrink-0 rounded-full bg-mboa-primary" aria-hidden />}
        </button>
      ))}
    </div>
  );
}
