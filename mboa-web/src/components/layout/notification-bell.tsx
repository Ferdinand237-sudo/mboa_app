"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { useUnreadNotifications } from "@/lib/hooks/use-unread-notifications";
import { BellIcon } from "@/components/ui/icons";
import type { NotificationRow } from "@/lib/data/notifications";

const ICONES: Record<NotificationRow["type"], string> = {
  message: "💬",
  avis: "⭐",
  annonce: "🏘",
};

function formatRelatif(dateStr: string): string {
  const diffMs = Date.now() - new Date(dateStr).getTime();
  const minutes = Math.floor(diffMs / 60000);
  const hours = Math.floor(diffMs / 3600000);
  const days = Math.floor(diffMs / 86400000);
  if (minutes < 60) return `Il y a ${minutes} min`;
  if (hours < 24) return `Il y a ${hours} h`;
  if (days < 7) return `Il y a ${days} j`;
  return new Date(dateStr).toLocaleDateString("fr-FR");
}

// Cloche de notifications présente dans le header sur toutes les pages
// (miroir web du centre de notifications alimenté par les mêmes évènements
// que le push FCM mobile — voir notifications.ts). Le compteur est tenu à
// jour en temps réel ; la liste déroulante n'est chargée qu'à l'ouverture,
// pour ne pas payer une requête Supabase supplémentaire sur chaque page.
export function NotificationBell({ userId, initialCount }: { userId: string; initialCount: number }) {
  const [open, setOpen] = useState(false);
  const [items, setItems] = useState<NotificationRow[] | null>(null);
  const [loading, setLoading] = useState(false);
  const count = useUnreadNotifications(userId, initialCount);
  const router = useRouter();

  async function toggle() {
    const next = !open;
    setOpen(next);
    if (next && items === null) {
      setLoading(true);
      const supabase = createClient();
      const { data } = await supabase
        .from("notifications")
        .select("id, type, titre, corps, lien, lu, created_at")
        .eq("user_id", userId)
        .order("created_at", { ascending: false })
        .limit(8);
      setItems(
        (data ?? []).map((r) => ({
          id: r.id as string,
          type: r.type as NotificationRow["type"],
          titre: r.titre as string,
          corps: r.corps as string | null,
          lien: r.lien as string | null,
          lu: r.lu as boolean,
          createdAt: r.created_at as string,
        })),
      );
      setLoading(false);
    }
  }

  async function ouvrir(n: NotificationRow) {
    setOpen(false);
    if (!n.lu) {
      const supabase = createClient();
      await supabase.from("notifications").update({ lu: true }).eq("id", n.id);
      setItems((prev) => prev?.map((x) => (x.id === n.id ? { ...x, lu: true } : x)) ?? prev);
    }
    if (n.lien) router.push(n.lien);
  }

  return (
    <div className="relative">
      <button
        type="button"
        onClick={toggle}
        aria-label="Notifications"
        className="relative flex h-10 w-10 items-center justify-center rounded-mboa-md text-mboa-text-muted transition-colors hover:bg-mboa-background hover:text-mboa-primary"
      >
        <BellIcon className="h-5 w-5" />
        {count > 0 && (
          <span className="absolute right-1 top-1 flex h-4 min-w-4 items-center justify-center rounded-full bg-mboa-danger px-1 text-[9px] font-bold text-white">
            {count > 9 ? "9+" : count}
          </span>
        )}
      </button>

      {open && (
        <>
          <div className="fixed inset-0 z-40" onClick={() => setOpen(false)} />
          <div className="absolute right-0 z-50 mt-2 w-80 max-w-[calc(100vw-2rem)] overflow-hidden rounded-mboa-lg border border-mboa-border bg-mboa-card shadow-lg">
            <div className="flex items-center justify-between border-b border-mboa-border px-4 py-3">
              <p className="text-sm font-bold text-mboa-text">Notifications</p>
              <Link
                href="/notifications"
                onClick={() => setOpen(false)}
                className="text-xs font-semibold text-mboa-primary"
              >
                Voir tout
              </Link>
            </div>
            <div className="max-h-80 overflow-y-auto">
              {loading ? (
                <p className="px-4 py-8 text-center text-xs text-mboa-text-muted">Chargement...</p>
              ) : !items || items.length === 0 ? (
                <p className="px-4 py-8 text-center text-xs text-mboa-text-muted">Aucune notification</p>
              ) : (
                items.map((n) => (
                  <button
                    key={n.id}
                    type="button"
                    onClick={() => ouvrir(n)}
                    className={`flex w-full items-start gap-2.5 px-4 py-3 text-left ${n.lu ? "" : "bg-mboa-primary/5"}`}
                  >
                    <span className="text-base" aria-hidden>
                      {ICONES[n.type]}
                    </span>
                    <div className="min-w-0 flex-1">
                      <p className={`truncate text-[13px] ${n.lu ? "font-medium text-mboa-text" : "font-bold text-mboa-text"}`}>
                        {n.titre}
                      </p>
                      {n.corps && <p className="mt-0.5 truncate text-xs text-mboa-text-muted">{n.corps}</p>}
                      <p className="mt-0.5 text-[10px] text-mboa-text-muted">{formatRelatif(n.createdAt)}</p>
                    </div>
                    {!n.lu && <span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-mboa-primary" aria-hidden />}
                  </button>
                ))
              )}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
