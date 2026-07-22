import type { Metadata } from "next";
import { getCurrentUser } from "@/lib/data/auth";
import { getAmbassadeurStats } from "@/lib/data/ambassadeur";

export const metadata: Metadata = {
  title: "Dashboard ambassadeur",
};

// Miroir de AmbassadeurDashboardScreen (ambassadeur_dashboard_screen.dart).
export default async function AmbassadeurDashboardPage() {
  const user = await getCurrentUser();
  const stats = await getAmbassadeurStats(user!.id);

  return (
    <div className="mx-auto max-w-3xl px-5 py-5">
      <h1 className="text-[22px] font-extrabold text-mboa-text">🧭 Ambassadeur Mboa</h1>
      <p className="mt-1 text-sm text-mboa-text-muted">Bonjour {stats.nom}</p>

      <div className="mt-6 grid grid-cols-2 gap-3">
        <StatCard emoji="🏠" label="À visiter" value={stats.nbAssignes} colorClass="text-mboa-boost" />
        <StatCard emoji="📤" label="En attente admin" value={stats.nbEnAttenteAdmin} colorClass="text-mboa-primary" />
        <StatCard emoji="✅" label="Validées" value={stats.nbValidees} colorClass="text-mboa-verified" />
        <StatCard emoji="❌" label="Rejetées" value={stats.nbRejetees} colorClass="text-mboa-danger" />
      </div>

      <div className="mt-6 flex items-start gap-2.5 rounded-mboa-lg bg-mboa-primary/8 p-4">
        <span aria-hidden>ℹ️</span>
        <p className="text-[12.5px] text-mboa-text">
          Retrouve la liste de tes propriétaires assignés dans l&apos;onglet « Assignés ».
        </p>
      </div>
    </div>
  );
}

function StatCard({
  emoji,
  label,
  value,
  colorClass,
}: {
  emoji: string;
  label: string;
  value: number;
  colorClass: string;
}) {
  return (
    <div className="rounded-mboa-lg bg-mboa-card p-4 shadow-sm">
      <span className="text-2xl">{emoji}</span>
      <p className={`mt-3 text-[26px] font-extrabold ${colorClass}`}>{value}</p>
      <p className="text-[11.5px] font-semibold text-mboa-text-muted">{label}</p>
    </div>
  );
}
