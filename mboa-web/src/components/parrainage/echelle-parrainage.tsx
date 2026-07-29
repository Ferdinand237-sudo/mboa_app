import type { PalierParrainage } from "@/lib/data/parrainage";

export function EchelleParrainage({ paliers, credits }: { paliers: PalierParrainage[]; credits: number }) {
  return (
    <div className="divide-y divide-mboa-border rounded-mboa-lg border border-mboa-border bg-mboa-card">
      {paliers.map((p) => {
        const atteint = credits >= p.seuilCredits;
        return (
          <div key={p.nom} className="flex items-center gap-3 px-4 py-3">
            <span
              className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-mboa-md text-lg ${
                atteint ? "bg-mboa-primary/12" : "bg-mboa-text-muted/10 grayscale"
              }`}
            >
              {p.icone}
            </span>
            <div className="flex-1">
              <p className={`text-sm font-bold ${atteint ? "text-mboa-text" : "text-mboa-text-muted"}`}>
                {p.nom}
              </p>
              <p className="text-[11px] text-mboa-text-muted">{p.seuilCredits} crédits</p>
            </div>
            {atteint && <span className="text-mboa-primary">✓</span>}
          </div>
        );
      })}
    </div>
  );
}
