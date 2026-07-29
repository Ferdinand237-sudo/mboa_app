import type { Filleul } from "@/lib/data/parrainage";
import { formatRelativeDate } from "@/lib/utils/format";

export function ListeFilleuls({ filleuls }: { filleuls: Filleul[] }) {
  if (filleuls.length === 0) {
    return (
      <div className="rounded-mboa-md bg-mboa-card p-4 text-center text-sm text-mboa-text-muted">
        Aucun filleul pour l&apos;instant — partage ton code pour commencer !
      </div>
    );
  }

  return (
    <div className="divide-y divide-mboa-border rounded-mboa-lg border border-mboa-border bg-mboa-card">
      {filleuls.map((f) => (
        <div key={f.id} className="flex items-center gap-3 px-4 py-3">
          <span className="text-lg">{f.type === "vendeur" ? "🏪" : "🎓"}</span>
          <div className="flex-1">
            <p className="text-sm font-semibold text-mboa-text">{f.nom}</p>
            <p className="text-[11px] text-mboa-text-muted">{formatRelativeDate(f.createdAt)}</p>
          </div>
          {f.statut === "valide" ? (
            <span className="rounded-mboa-full bg-mboa-primary/10 px-2.5 py-1 text-[11px] font-bold text-mboa-primary">
              +{f.creditsAttribues} crédits
            </span>
          ) : (
            <span className="rounded-mboa-full bg-mboa-boost/10 px-2.5 py-1 text-[11px] font-bold text-mboa-boost">
              En attente
            </span>
          )}
        </div>
      ))}
    </div>
  );
}
