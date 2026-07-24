"use client";

import { useState } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import { ConfirmDialog } from "@/components/admin/confirm-dialog";
import { CreateAmbassadeurDialog } from "@/components/admin/create-ambassadeur-dialog";
import { initiales } from "@/lib/utils/format";
import type { AdminUser } from "@/lib/data/admin";

const ROLE_STYLE: Record<string, { label: string; color: string; bg: string }> = {
  admin: { label: "👑 Admin", color: "text-mboa-accent", bg: "bg-mboa-accent/10" },
  vendeur: { label: "🏪 Vendeur", color: "text-mboa-secondary", bg: "bg-mboa-secondary/10" },
  ambassadeur: { label: "🧭 Ambassadeur", color: "text-mboa-primary-dark", bg: "bg-mboa-primary-dark/10" },
  visiteur: { label: "🎓 Visiteur", color: "text-mboa-primary", bg: "bg-mboa-primary/10" },
};

const VERIF_STYLE: Record<string, { label: string; color: string }> = {
  en_attente_assignation: { label: "🕓 À assigner", color: "text-mboa-text-muted" },
  assignee: { label: "📍 Visite en cours", color: "text-mboa-boost" },
  visite_effectuee: { label: "📤 À valider", color: "text-mboa-primary" },
  validee: { label: "✅ Vérifié terrain", color: "text-mboa-verified" },
  rejetee: { label: "❌ Vérif. rejetée", color: "text-mboa-danger" },
};

type ToggleField = "actif" | "verified";

// Miroir de AdminUsersScreen (admin_users_screen.dart).
export function UsersClient({ users: initial }: { users: AdminUser[] }) {
  const [users, setUsers] = useState(initial);
  const [ambassadeurOpen, setAmbassadeurOpen] = useState(false);
  const [confirm, setConfirm] = useState<{ userId: string; field: ToggleField; current: boolean } | null>(null);
  const [busy, setBusy] = useState(false);

  async function appliquer() {
    if (!confirm) return;
    setBusy(true);
    const supabase = createClient();
    const { error } = await supabase
      .from("users")
      .update({ [confirm.field]: !confirm.current })
      .eq("id", confirm.userId);
    setBusy(false);
    if (!error) {
      setUsers((prev) =>
        prev.map((u) => (u.id === confirm.userId ? { ...u, [confirm.field]: !confirm.current } : u)),
      );
    }
    setConfirm(null);
  }

  const titre =
    confirm?.field === "actif"
      ? confirm.current
        ? "🚫 Bannir ce compte"
        : "✅ Réactiver ce compte"
      : confirm?.current
        ? "🚫 Retirer la certification"
        : "✅ Certifier ce compte";
  const body =
    confirm?.field === "actif"
      ? confirm.current
        ? "Ce compte sera banni et l'utilisateur ne pourra plus se connecter."
        : "Ce compte sera réactivé et l'utilisateur pourra se reconnecter."
      : confirm?.current
        ? "Cette action retirera la certification de ce compte."
        : "Cette action certifiera ce compte.";
  const confirmLabel =
    confirm?.field === "actif" ? (confirm.current ? "Bannir" : "Réactiver") : confirm?.current ? "Décertifier" : "Certifier";

  return (
    <div>
      <div className="rounded-b-[32px] bg-white px-5 py-4 shadow-sm">
        <div className="mx-auto flex max-w-4xl flex-wrap items-center justify-between gap-3">
          <h1 className="text-[22px] font-extrabold text-mboa-text">👥 Utilisateurs</h1>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => setAmbassadeurOpen(true)}
              className="rounded-mboa-md border border-mboa-border px-3 py-2 text-xs font-semibold text-mboa-text"
            >
              ➕ Ambassadeur
            </button>
            <Link
              href="/admin/demandes"
              className="rounded-mboa-md border border-mboa-border px-3 py-2 text-xs font-semibold text-mboa-text"
            >
              ✉️ Demandes Pro
            </Link>
          </div>
        </div>
      </div>

      <div className="mx-auto max-w-4xl px-4 py-4 pb-10">
        <div className="flex flex-col gap-2.5">
          {users.map((u) => {
            const roleStyle = ROLE_STYLE[u.role] ?? ROLE_STYLE.visiteur;
            const verifStyle = u.statutVerification ? VERIF_STYLE[u.statutVerification] : null;
            return (
              <div
                key={u.id}
                className={`rounded-mboa-lg border bg-mboa-card p-3.5 shadow-sm ${
                  u.actif ? "border-mboa-border" : "border-mboa-danger/30"
                }`}
              >
                <div className="flex items-center gap-3">
                  <span
                    className={`flex h-[46px] w-[46px] shrink-0 items-center justify-center rounded-full text-base font-bold ${roleStyle.color} ${roleStyle.bg}`}
                  >
                    {initiales(u.nom)}
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="flex items-center gap-1 text-sm font-bold text-mboa-text">
                      <span className="truncate">{u.nom}</span>
                      {u.verified && <span className="shrink-0 text-mboa-verified">✅</span>}
                    </p>
                    <p className="truncate text-xs text-mboa-text-muted">{u.email}</p>
                    <div className="mt-1 flex flex-wrap gap-1.5">
                      <span className={`rounded-full px-2 py-0.5 text-[10px] font-bold ${roleStyle.color} ${roleStyle.bg}`}>
                        {roleStyle.label}
                      </span>
                      {verifStyle && (
                        <span className={`rounded-full bg-mboa-background px-2 py-0.5 text-[10px] font-bold ${verifStyle.color}`}>
                          {verifStyle.label}
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                {u.role !== "admin" && (
                  <div className="mt-3 flex justify-evenly gap-2 border-t border-mboa-border pt-2.5">
                    <button
                      type="button"
                      onClick={() => setConfirm({ userId: u.id, field: "verified", current: u.verified })}
                      className="flex items-center gap-1.5 rounded-mboa-md border border-mboa-verified/30 bg-mboa-verified/8 px-3.5 py-1.5 text-xs font-bold text-mboa-verified"
                    >
                      {u.verified ? "✅ Certifié" : "Certifier"}
                    </button>
                    <button
                      type="button"
                      onClick={() => setConfirm({ userId: u.id, field: "actif", current: u.actif })}
                      className={`flex items-center gap-1.5 rounded-mboa-md border px-3.5 py-1.5 text-xs font-bold ${
                        u.actif
                          ? "border-mboa-danger/30 bg-mboa-danger/8 text-mboa-danger"
                          : "border-mboa-verified/30 bg-mboa-verified/8 text-mboa-verified"
                      }`}
                    >
                      {u.actif ? "🚫 Bannir" : "✅ Réactiver"}
                    </button>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>

      <ConfirmDialog
        open={confirm !== null}
        onClose={() => setConfirm(null)}
        title={titre}
        body={body}
        confirmLabel={confirmLabel}
        confirmClass={confirm?.current ? "bg-mboa-danger" : "bg-mboa-verified"}
        busy={busy}
        onConfirm={appliquer}
      />
      <CreateAmbassadeurDialog open={ambassadeurOpen} onClose={() => setAmbassadeurOpen(false)} />
    </div>
  );
}
