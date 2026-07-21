import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";
import { initiales, formatDateFr } from "@/lib/utils/format";
import { Badge } from "@/components/ui/badge";
import { Rating } from "@/components/ui/rating";
import { LogoutButton } from "@/components/profil/logout-button";

export const metadata: Metadata = {
  title: "Mon profil",
};

const ROLE_LABELS: Record<string, string> = {
  visiteur: "Étudiant",
  vendeur: "Vendeur",
  admin: "Administrateur",
  ambassadeur: "Ambassadeur",
};

export default async function ProfilPage() {
  const user = await getCurrentUser();

  if (!user) {
    redirect("/login");
  }

  return (
    <div className="mx-auto max-w-2xl px-4 py-12 sm:px-6">
      <div className="flex flex-col items-center rounded-mboa-xl border border-mboa-border bg-mboa-card p-8 text-center">
        <span className="flex h-20 w-20 items-center justify-center rounded-full bg-mboa-primary text-2xl font-bold text-white">
          {initiales(user.nom)}
        </span>
        <h1 className="mt-4 flex items-center gap-1.5 text-xl font-extrabold text-mboa-text">
          {user.nom}
          {user.verified && <span title="Vérifié">✓</span>}
        </h1>
        <p className="text-sm text-mboa-text-muted">{user.email}</p>

        <div className="mt-3 flex flex-wrap items-center justify-center gap-2">
          <Badge variant="neutral">
            {ROLE_LABELS[user.role] ?? user.role}
          </Badge>
          {user.verified && <Badge variant="verified">✓ Vérifié</Badge>}
          {user.boosted && <Badge variant="boost">✦ Boosté</Badge>}
        </div>

        <div className="mt-4">
          <Rating note={user.noteGlobale} nbAvis={user.nbAvis} />
        </div>

        <p className="mt-4 text-xs text-mboa-text-muted">
          Membre depuis le {formatDateFr(user.dateInscription)}
        </p>

        <div className="mt-8 w-full border-t border-mboa-border pt-6">
          <LogoutButton />
        </div>
      </div>
    </div>
  );
}
