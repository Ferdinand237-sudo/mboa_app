import type { PalierParrainage } from "@/lib/data/parrainage";

export function PalierProgression({
  credits,
  palierActuel,
  palierSuivant,
}: {
  credits: number;
  palierActuel: PalierParrainage;
  palierSuivant: PalierParrainage | null;
}) {
  const progression = palierSuivant
    ? Math.min(
        100,
        Math.round(
          ((credits - palierActuel.seuilCredits) / (palierSuivant.seuilCredits - palierActuel.seuilCredits)) * 100,
        ),
      )
    : 100;

  return (
    <div className="rounded-mboa-lg border border-mboa-border bg-mboa-card p-4">
      <div className="flex items-center gap-3">
        <span className="flex h-12 w-12 items-center justify-center rounded-full bg-mboa-primary/10 text-2xl">
          {palierActuel.icone}
        </span>
        <div>
          <p className="text-base font-extrabold text-mboa-text">{palierActuel.nom}</p>
          <p className="text-xs text-mboa-text-muted">{credits} crédits au total</p>
        </div>
      </div>

      <div className="mt-4">
        <div className="h-2.5 w-full overflow-hidden rounded-mboa-full bg-mboa-background">
          <div
            className="h-full rounded-mboa-full bg-mboa-primary transition-all"
            style={{ width: `${progression}%` }}
          />
        </div>
        <p className="mt-2 text-xs text-mboa-text-muted">
          {palierSuivant
            ? `Encore ${palierSuivant.seuilCredits - credits} crédits pour ${palierSuivant.icone} ${palierSuivant.nom}`
            : "Palier maximum atteint 🎉"}
        </p>
      </div>
    </div>
  );
}
