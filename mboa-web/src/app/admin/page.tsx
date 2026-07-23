import type { Metadata } from "next";
import Link from "next/link";
import { getAdminStats } from "@/lib/data/admin";
import { LogoutButton } from "@/components/profil/logout-button";

export const metadata: Metadata = {
  title: "Dashboard admin",
};

const ACTIONS = [
  {
    icon: "🗺️",
    titre: "Gérer la carte",
    desc: "Ajouter des lieux publics (écoles, hôpitaux, marchés...) visibles par tous",
    color: "text-mboa-primary",
    bg: "bg-mboa-primary/12",
    href: "/carte",
  },
  {
    icon: "👤",
    titre: "Créer un compte vendeur",
    desc: "Approuver et créer un compte pour un commerçant ou propriétaire",
    color: "text-mboa-secondary",
    bg: "bg-mboa-secondary/12",
    href: "/admin/demandes",
  },
  {
    icon: "🚀",
    titre: "Booster une annonce",
    desc: "Mettre en avant une annonce logement ou marketplace",
    color: "text-mboa-boost",
    bg: "bg-mboa-boost/12",
    href: "/admin/annonces",
  },
  {
    icon: "✅",
    titre: "Certifier un vendeur",
    desc: "Attribuer le badge Vérifié à un vendeur de confiance",
    color: "text-mboa-verified",
    bg: "bg-mboa-verified/12",
    href: "/admin/utilisateurs",
  },
  {
    icon: "⛔",
    titre: "Gérer les bannissements",
    desc: "Bannir ou réactiver un compte utilisateur",
    color: "text-mboa-danger",
    bg: "bg-mboa-danger/12",
    href: "/admin/utilisateurs",
  },
];

// Miroir de _DashboardTab (admin_screen.dart).
export default async function AdminDashboardPage() {
  const stats = await getAdminStats();
  const hasAlertes = stats.signalements > 0 || stats.demandes > 0;

  return (
    <div>
      <div className="bg-gradient-to-br from-mboa-primary-dark via-mboa-primary to-mboa-primary-light px-5 py-6">
        <div className="mx-auto max-w-7xl">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-[13px] text-white/80">Bonjour Admin 👋</p>
              <h1 className="text-[22px] font-extrabold text-white">Dashboard Mboa</h1>
            </div>
            <LogoutButton variant="icon" />
          </div>

          <div className="mt-5 grid grid-cols-3 gap-3">
            <QuickStat emoji="👥" value={stats.users} label="Utilisateurs" />
            <QuickStat emoji="🏠" value={stats.logements} label="Logements" />
            <QuickStat emoji="🛒" value={stats.articles} label="Articles" />
          </div>
        </div>
      </div>

      <div className="mx-auto max-w-7xl px-5 py-5">
        {hasAlertes && (
          <div className="mb-6">
            <p className="text-base font-bold text-mboa-text">🚨 Actions requises</p>
            <div className="mt-3 flex flex-col gap-2.5">
              {stats.demandes > 0 && (
                <AlertCard
                  icon="📨"
                  titre="Demandes de compte"
                  desc={`${stats.demandes} demande(s) en attente d'approbation`}
                  colorClass="text-mboa-secondary"
                  borderClass="border-mboa-secondary/30"
                  bgClass="bg-mboa-secondary/8"
                  href="/admin/demandes"
                />
              )}
              {stats.signalements > 0 && (
                <AlertCard
                  icon="🚩"
                  titre="Signalements"
                  desc={`${stats.signalements} signalement(s) à traiter`}
                  colorClass="text-mboa-danger"
                  borderClass="border-mboa-danger/30"
                  bgClass="bg-mboa-danger/8"
                  href="/admin/signalements"
                />
              )}
            </div>
          </div>
        )}

        <p className="text-base font-bold text-mboa-text">Actions rapides</p>
        <div className="mt-3 flex flex-col gap-3">
          {ACTIONS.map((a) => (
            <Link
              key={a.titre}
              href={a.href}
              className="flex items-center gap-3.5 rounded-mboa-lg bg-mboa-card p-4 shadow-sm"
            >
              <span className={`flex h-[46px] w-[46px] shrink-0 items-center justify-center rounded-2xl text-xl ${a.bg}`}>
                {a.icon}
              </span>
              <div className="min-w-0 flex-1">
                <p className="text-sm font-bold text-mboa-text">{a.titre}</p>
                <p className="mt-0.5 text-xs leading-relaxed text-mboa-text-muted">{a.desc}</p>
              </div>
              <span className="text-mboa-text-muted">›</span>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}

function QuickStat({ emoji, value, label }: { emoji: string; value: number; label: string }) {
  return (
    <div className="flex flex-col items-center rounded-2xl bg-white/15 py-3">
      <span className="text-xl">{emoji}</span>
      <span className="mt-1 text-xl font-extrabold text-white">{value}</span>
      <span className="text-[10px] text-white/75">{label}</span>
    </div>
  );
}

function AlertCard({
  icon,
  titre,
  desc,
  colorClass,
  borderClass,
  bgClass,
  href,
}: {
  icon: string;
  titre: string;
  desc: string;
  colorClass: string;
  borderClass: string;
  bgClass: string;
  href: string;
}) {
  return (
    <Link href={href} className={`flex items-center gap-3 rounded-mboa-md border p-3.5 ${borderClass} ${bgClass}`}>
      <span className="text-2xl" aria-hidden>
        {icon}
      </span>
      <div className="min-w-0 flex-1">
        <p className={`text-[13px] font-bold ${colorClass}`}>{titre}</p>
        <p className="text-[11px] text-mboa-text-muted">{desc}</p>
      </div>
      <span className={colorClass}>›</span>
    </Link>
  );
}
