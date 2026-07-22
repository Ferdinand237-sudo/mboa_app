"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import type { AssignationItem } from "@/lib/data/ambassadeur";

const STATUT_STYLE: Record<string, { label: string; color: string }> = {
  assignee: { label: "📍 À visiter", color: "text-mboa-boost bg-mboa-boost/10" },
  visite_effectuee: { label: "📤 Envoyé à l'admin", color: "text-mboa-primary bg-mboa-primary/10" },
  validee: { label: "✅ Validée", color: "text-mboa-verified bg-mboa-verified/10" },
  rejetee: { label: "❌ Rejetée", color: "text-mboa-danger bg-mboa-danger/10" },
};

// Miroir de AmbassadeurListeScreen : abonnement realtime filtré côté
// serveur sur ambassadeur_id, une nouvelle assignation apparaît sans
// recharger manuellement (voir CLAUDE.md, section temps réel).
export function AssignationsList({ assignations, userId }: { assignations: AssignationItem[]; userId: string }) {
  const router = useRouter();

  useEffect(() => {
    const supabase = createClient();
    const channel = supabase
      .channel(`ambassadeur_liste_${userId}`)
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "verifications_terrain", filter: `ambassadeur_id=eq.${userId}` },
        () => router.refresh(),
      )
      .subscribe();
    return () => {
      supabase.removeChannel(channel);
    };
  }, [userId, router]);

  if (assignations.length === 0) {
    return (
      <div className="flex flex-col items-center px-8 py-24 text-center">
        <span className="text-6xl" aria-hidden>
          🧭
        </span>
        <p className="mt-4 text-sm text-mboa-text-muted">Aucun propriétaire assigné pour l&apos;instant</p>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-3xl px-4 py-4 pb-10">
      <div className="flex flex-col gap-2.5">
        {assignations.map((a) => {
          const style = STATUT_STYLE[a.statut] ?? {
            label: a.statut,
            color: "text-mboa-text-muted bg-mboa-text-muted/10",
          };
          return (
            <Link
              key={a.id}
              href={`/ambassadeur/visites/${a.id}`}
              className="flex items-center gap-3 rounded-mboa-lg bg-mboa-card p-3.5 shadow-sm"
            >
              <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-mboa-primary/10 text-lg">
                🏠
              </span>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-bold text-mboa-text">{a.proprietaireNom}</p>
                <p className="truncate text-xs text-mboa-text-muted">{a.proprietaireContact}</p>
              </div>
              <span className={`shrink-0 rounded-full px-2.5 py-1 text-[10.5px] font-bold ${style.color}`}>
                {style.label}
              </span>
            </Link>
          );
        })}
      </div>
    </div>
  );
}
