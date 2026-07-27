"use client";

import { useState } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import { ConfirmDialog } from "@/components/admin/confirm-dialog";
import { CreateAmbassadeurDialog } from "@/components/admin/create-ambassadeur-dialog";
import { FilterPills } from "@/components/admin/filter-pills";
import { VerifiedBadge } from "@/components/ui/verified-badge";
import { initiales } from "@/lib/utils/format";
import type { AdminUser } from "@/lib/data/admin";

// role reste l'identité de base (compte historiquement créé comme
// visiteur ou vendeur) ; admin/ambassadeur sont des privilèges superposés
// (estAdmin/estAmbassadeur) affichés comme badges supplémentaires plutôt
// que remplaçant ce badge de base — voir la migration
// roles_multiples_admin_ambassadeur.
const ROLE_STYLE: Record<string, { label: string; color: string; bg: string }> = {
  vendeur: { label: "🏪 Vendeur", color: "text-mboa-secondary", bg: "bg-mboa-secondary/10" },
  visiteur: { label: "🎓 Visiteur", color: "text-mboa-primary", bg: "bg-mboa-primary/10" },
};

const FILTRES_ROLE = [
  { value: "tous", label: "Tous" },
  { value: "visiteur", label: "🎓 Visiteurs" },
  { value: "vendeur", label: "🏪 Vendeurs" },
  { value: "ambassadeur", label: "🧭 Ambassadeurs" },
  { value: "admin", label: "👑 Admins" },
] as const;

const VERIF_STYLE: Record<string, { label: string; color: string }> = {
  en_attente_assignation: { label: "🕓 À assigner", color: "text-mboa-text-muted" },
  assignee: { label: "📍 Visite en cours", color: "text-mboa-boost" },
  visite_effectuee: { label: "📤 À valider", color: "text-mboa-primary" },
  validee: { label: "✅ Vérifié terrain", color: "text-mboa-verified" },
  rejetee: { label: "❌ Vérif. rejetée", color: "text-mboa-danger" },
};

type ToggleField = "actif" | "verified" | "est_admin" | "est_ambassadeur";

const CONFIRM_COPY: Record<
  ToggleField,
  { titreOn: string; titreOff: string; bodyOn: string; bodyOff: string; labelOn: string; labelOff: string }
> = {
  verified: {
    titreOn: "✅ Certifier ce compte",
    titreOff: "🚫 Retirer la certification",
    bodyOn: "Cette action certifiera ce compte.",
    bodyOff: "Cette action retirera la certification de ce compte.",
    labelOn: "Certifier",
    labelOff: "Décertifier",
  },
  actif: {
    titreOn: "✅ Réactiver ce compte",
    titreOff: "🚫 Bannir ce compte",
    bodyOn: "Ce compte sera réactivé et l'utilisateur pourra se reconnecter.",
    bodyOff: "Ce compte sera banni et l'utilisateur ne pourra plus se connecter.",
    labelOn: "Réactiver",
    labelOff: "Bannir",
  },
  est_admin: {
    titreOn: "👑 Nommer administrateur",
    titreOff: "Retirer les droits administrateur",
    bodyOn:
      "Ce compte garde son expérience actuelle (visiteur ou vendeur) et gagne en plus un lien « Administration » dans son profil pour accéder à l'ensemble des pages admin.",
    bodyOff: "Ce compte perdra l'accès à l'espace d'administration.",
    labelOn: "Nommer administrateur",
    labelOff: "Retirer",
  },
  est_ambassadeur: {
    titreOn: "🧭 Nommer ambassadeur",
    titreOff: "Retirer les droits ambassadeur",
    bodyOn:
      "Ce compte garde son expérience actuelle et gagne en plus un lien « Espace ambassadeur » dans son profil pour effectuer des vérifications terrain.",
    bodyOff: "Ce compte perdra l'accès à l'espace ambassadeur.",
    labelOn: "Nommer ambassadeur",
    labelOff: "Retirer",
  },
};

// Miroir de AdminUsersScreen (admin_users_screen.dart).
export function UsersClient({ users: initial }: { users: AdminUser[] }) {
  const [users, setUsers] = useState(initial);
  const [filtreRole, setFiltreRole] = useState<(typeof FILTRES_ROLE)[number]["value"]>("tous");
  const [ambassadeurOpen, setAmbassadeurOpen] = useState(false);
  const [confirm, setConfirm] = useState<{ userId: string; field: ToggleField; current: boolean } | null>(null);
  const [busy, setBusy] = useState(false);

  const affiches =
    filtreRole === "tous"
      ? users
      : filtreRole === "admin"
        ? users.filter((u) => u.estAdmin)
        : filtreRole === "ambassadeur"
          ? users.filter((u) => u.estAmbassadeur)
          : users.filter((u) => u.role === filtreRole);

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
      const champCamel = confirm.field === "est_admin" ? "estAdmin" : confirm.field === "est_ambassadeur" ? "estAmbassadeur" : confirm.field;
      setUsers((prev) =>
        prev.map((u) => (u.id === confirm.userId ? { ...u, [champCamel]: !confirm.current } : u)),
      );
    }
    setConfirm(null);
  }

  const copy = confirm ? CONFIRM_COPY[confirm.field] : null;
  const titre = copy ? (confirm?.current ? copy.titreOff : copy.titreOn) : "";
  const body = copy ? (confirm?.current ? copy.bodyOff : copy.bodyOn) : "";
  const confirmLabel = copy ? (confirm?.current ? copy.labelOff : copy.labelOn) : "";

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
        <div className="mx-auto mt-3 max-w-4xl pb-3">
          <FilterPills options={FILTRES_ROLE.slice()} value={filtreRole} onChange={setFiltreRole} />
        </div>
      </div>

      <div className="mx-auto max-w-4xl px-4 py-4 pb-10">
        {affiches.length === 0 ? (
          <p className="py-16 text-center text-sm text-mboa-text-muted">Aucun utilisateur dans ce filtre</p>
        ) : (
        <div className="flex flex-col gap-2.5">
          {affiches.map((u) => {
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
                      {u.verified && <VerifiedBadge className="h-3.5 w-3.5 shrink-0" />}
                    </p>
                    <p className="truncate text-xs text-mboa-text-muted">{u.email}</p>
                    <div className="mt-1 flex flex-wrap gap-1.5">
                      <span className={`rounded-full px-2 py-0.5 text-[10px] font-bold ${roleStyle.color} ${roleStyle.bg}`}>
                        {roleStyle.label}
                      </span>
                      {u.estAdmin && (
                        <span className="rounded-full bg-mboa-accent/10 px-2 py-0.5 text-[10px] font-bold text-mboa-accent">
                          👑 Admin
                        </span>
                      )}
                      {u.estAmbassadeur && (
                        <span className="rounded-full bg-mboa-primary-dark/10 px-2 py-0.5 text-[10px] font-bold text-mboa-primary-dark">
                          🧭 Ambassadeur
                        </span>
                      )}
                      {verifStyle && (
                        <span className={`rounded-full bg-mboa-background px-2 py-0.5 text-[10px] font-bold ${verifStyle.color}`}>
                          {verifStyle.label}
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                {!u.estAdmin && (
                  <div className="mt-3 flex flex-wrap justify-evenly gap-2 border-t border-mboa-border pt-2.5">
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

                {/* Attribution des privilèges admin/ambassadeur : choisir
                    parmi les utilisateurs existants, sans passer par la
                    création d'un nouveau compte (voir CreateAmbassadeurDialog
                    pour créer un ambassadeur avec un compte tout neuf). */}
                <div className="mt-2 flex flex-wrap justify-evenly gap-2 border-t border-mboa-border pt-2.5">
                  <button
                    type="button"
                    onClick={() => setConfirm({ userId: u.id, field: "est_admin", current: u.estAdmin })}
                    className={`flex items-center gap-1.5 rounded-mboa-md border px-3.5 py-1.5 text-xs font-bold ${
                      u.estAdmin
                        ? "border-mboa-accent/30 bg-mboa-accent/8 text-mboa-accent"
                        : "border-mboa-border text-mboa-text-muted"
                    }`}
                  >
                    {u.estAdmin ? "👑 Admin" : "Nommer administrateur"}
                  </button>
                  <button
                    type="button"
                    onClick={() => setConfirm({ userId: u.id, field: "est_ambassadeur", current: u.estAmbassadeur })}
                    className={`flex items-center gap-1.5 rounded-mboa-md border px-3.5 py-1.5 text-xs font-bold ${
                      u.estAmbassadeur
                        ? "border-mboa-primary-dark/30 bg-mboa-primary-dark/8 text-mboa-primary-dark"
                        : "border-mboa-border text-mboa-text-muted"
                    }`}
                  >
                    {u.estAmbassadeur ? "🧭 Ambassadeur" : "Nommer ambassadeur"}
                  </button>
                </div>
              </div>
            );
          })}
        </div>
        )}
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
