"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { Photo } from "@/components/ui/photo";
import { VerifiedBadge } from "@/components/ui/verified-badge";
import { initiales } from "@/lib/utils/format";
import type { ConversationItem } from "@/lib/data/chat";

const FILTRES = [
  { value: "tous", label: "Tous" },
  { value: "logement", label: "🏠 Logements" },
  { value: "article", label: "🛒 Market" },
] as const;

function formatHeure(dateStr: string | null): string {
  if (!dateStr) return "";
  const date = new Date(dateStr);
  const now = new Date();
  const diffDays = Math.floor((now.getTime() - date.getTime()) / 86400000);
  if (diffDays === 0) {
    return `${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`;
  }
  if (diffDays === 1) return "Hier";
  if (diffDays < 7) {
    const jours = ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"];
    return jours[date.getDay()];
  }
  return `${date.getDate()}/${date.getMonth() + 1}`;
}

// Miroir de ChatScreen (chat_screen.dart) : filtres logement/article + liste.
export function ChatList({ conversations }: { conversations: ConversationItem[] }) {
  const [filtre, setFiltre] = useState<(typeof FILTRES)[number]["value"]>("tous");

  const affichees = useMemo(
    () => (filtre === "tous" ? conversations : conversations.filter((c) => c.annonceType === filtre)),
    [conversations, filtre],
  );

  return (
    <div className="lg:mx-auto lg:mb-10 lg:mt-6 lg:max-w-2xl lg:overflow-hidden lg:rounded-2xl lg:border lg:border-mboa-border lg:shadow-sm">
      <div className="bg-white px-5 pb-4 pt-4">
        <div className="mx-auto flex max-w-2xl items-center justify-between">
          <h1 className="text-[22px] font-extrabold text-mboa-text">💬 Messages</h1>
          {conversations.length > 0 && (
            <span className="rounded-full bg-mboa-primary/10 px-3 py-1.5 text-xs font-bold text-mboa-primary">
              {conversations.length} conversation{conversations.length > 1 ? "s" : ""}
            </span>
          )}
        </div>
        {conversations.length > 0 && (
          <div className="mx-auto mt-3 flex max-w-2xl gap-2">
            {FILTRES.map((f) => {
              const isSelected = filtre === f.value;
              return (
                <button
                  key={f.value}
                  type="button"
                  onClick={() => setFiltre(f.value)}
                  className={`rounded-full border px-3.5 py-1.5 text-xs font-semibold ${
                    isSelected
                      ? "border-mboa-primary bg-mboa-primary text-white"
                      : "border-mboa-border bg-mboa-background text-mboa-text"
                  }`}
                >
                  {f.label}
                </button>
              );
            })}
          </div>
        )}
      </div>

      {conversations.length === 0 ? (
        <div className="flex flex-col items-center px-8 py-24 text-center">
          <span className="text-6xl" aria-hidden>
            💬
          </span>
          <p className="mt-4 text-base font-bold text-mboa-text">Aucun message</p>
          <p className="mt-2 max-w-xs text-sm leading-relaxed text-mboa-text-muted">
            Contacte un vendeur depuis une annonce pour démarrer une conversation
          </p>
        </div>
      ) : affichees.length === 0 ? (
        <p className="py-16 text-center text-sm text-mboa-text-muted">Aucune conversation dans ce filtre</p>
      ) : (
        <div className="mx-auto max-w-2xl divide-y divide-mboa-border">
          {affichees.map((c) => (
            <Link
              key={c.id}
              href={`/chat/${c.id}`}
              className={`flex items-center gap-3.5 px-5 py-3.5 ${c.nbNonLu > 0 ? "bg-mboa-primary/3" : "bg-white"}`}
            >
              <div className="relative shrink-0">
                <div className="relative h-[52px] w-[52px] overflow-hidden rounded-full bg-mboa-primary">
                  {c.autrePhotoUrl ? (
                    <Photo src={c.autrePhotoUrl} alt={c.autreNom} className="rounded-full" />
                  ) : (
                    <span className="flex h-full w-full items-center justify-center text-lg font-bold text-white">
                      {initiales(c.autreNom)}
                    </span>
                  )}
                </div>
                <span className="absolute -bottom-0.5 -right-0.5 flex h-5 w-5 items-center justify-center rounded-full border border-mboa-border bg-white text-[10px]">
                  💬
                </span>
              </div>

              <div className="min-w-0 flex-1">
                <div className="flex items-center justify-between gap-2">
                  <span className="flex min-w-0 items-center gap-1">
                    <span
                      className={`truncate text-sm text-mboa-text ${c.nbNonLu > 0 ? "font-bold" : "font-semibold"}`}
                    >
                      {c.autreNom}
                    </span>
                    {c.autreVerified && <VerifiedBadge className="h-3.5 w-3.5 shrink-0" />}
                  </span>
                  <span
                    className={`shrink-0 text-[11px] ${c.nbNonLu > 0 ? "font-semibold text-mboa-primary" : "text-mboa-text-muted"}`}
                  >
                    {formatHeure(c.dernierMessageDate)}
                  </span>
                </div>
                {c.annonceTitre && (
                  <p className="mt-0.5 truncate text-[11px] font-semibold text-mboa-primary">
                    {c.annonceType === "logement" ? "🏠" : "🛒"} {c.annonceTitre}
                  </p>
                )}
                <div className="mt-0.5 flex items-center justify-between gap-2">
                  <p
                    className={`min-w-0 flex-1 truncate text-xs ${c.nbNonLu > 0 ? "font-medium text-mboa-text" : "text-mboa-text-muted"}`}
                  >
                    {c.dernierMessage ?? "Conversation démarrée"}
                  </p>
                  {c.nbNonLu > 0 && (
                    <span className="flex h-[22px] w-[22px] shrink-0 items-center justify-center rounded-full bg-mboa-primary text-[11px] font-bold text-white">
                      {c.nbNonLu}
                    </span>
                  )}
                </div>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
