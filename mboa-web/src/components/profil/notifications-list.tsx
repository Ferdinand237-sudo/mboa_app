import Link from "next/link";
import type { NotificationItem } from "@/lib/data/notifications";

// Miroir de _formatDate (notifications_screen.dart).
function formatDate(dateStr: string | null): string {
  if (!dateStr) return "";
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

export function NotificationsList({ notifications }: { notifications: NotificationItem[] }) {
  if (notifications.length === 0) {
    return (
      <div className="flex flex-col items-center px-8 py-20 text-center">
        <span className="text-5xl" aria-hidden>
          🔕
        </span>
        <p className="mt-4 text-base font-bold text-mboa-text">Aucune notification</p>
        <p className="mt-2 max-w-xs text-sm text-mboa-text-muted">
          Tu seras notifié ici des nouveaux messages et avis.
        </p>
      </div>
    );
  }

  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-2 px-4 pb-10">
      {notifications.map((n, i) => {
        const isMessage = n.type === "message";
        const content = (
          <div className="flex items-center gap-3 rounded-mboa-md bg-mboa-card p-3.5 shadow-sm">
            <span
              className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl text-lg ${
                isMessage ? "bg-mboa-primary/12" : "bg-mboa-boost/12"
              }`}
            >
              {isMessage ? "💬" : "⭐"}
            </span>
            <div className="min-w-0 flex-1">
              <p className="text-[13px] font-semibold text-mboa-text">{n.texte}</p>
              <p className="mt-0.5 text-xs text-mboa-text-muted">{formatDate(n.date)}</p>
            </div>
          </div>
        );
        return isMessage ? (
          <Link key={i} href="/chat">
            {content}
          </Link>
        ) : (
          <div key={i}>{content}</div>
        );
      })}
    </div>
  );
}
