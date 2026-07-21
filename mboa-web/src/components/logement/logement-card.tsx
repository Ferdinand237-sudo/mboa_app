import Link from "next/link";
import type { LogementModel } from "@/lib/types/models";
import { formatPrix, photoPrincipale } from "@/lib/utils/format";
import { Badge } from "@/components/ui/badge";
import { Rating } from "@/components/ui/rating";
import { Photo } from "@/components/ui/photo";

export function LogementCard({ logement }: { logement: LogementModel }) {
  return (
    <Link
      href={`/logements/${logement.id}`}
      className="group flex flex-col overflow-hidden rounded-mboa-lg border border-mboa-border bg-mboa-card shadow-sm transition-shadow hover:shadow-md"
    >
      <div className="relative aspect-[4/3] w-full overflow-hidden">
        <Photo src={photoPrincipale(logement.photos)} alt={logement.titre} />
        <div className="absolute left-2 top-2 flex gap-1.5">
          {logement.boosted && <Badge variant="boost">✦ Boosté</Badge>}
        </div>
        <div className="absolute right-2 top-2">
          <Badge variant="neutral">{logement.type}</Badge>
        </div>
      </div>
      <div className="flex flex-1 flex-col gap-1.5 p-3.5">
        <div className="flex items-start justify-between gap-2">
          <h3 className="line-clamp-1 text-sm font-bold text-mboa-text">
            {logement.titre}
          </h3>
        </div>
        <p className="line-clamp-1 text-xs text-mboa-text-muted">
          📍 {logement.quartier ?? logement.ville}
        </p>
        <div className="mt-1 flex items-center justify-between">
          <span className="text-base font-extrabold text-mboa-primary">
            {formatPrix(logement.prix)}
          </span>
          <Rating note={logement.noteGlobale} nbAvis={logement.nbAvis} />
        </div>
        {logement.proprietaireVerified && (
          <div className="flex items-center gap-1 text-[11px] font-semibold text-mboa-verified">
            ✓ Propriétaire vérifié
          </div>
        )}
      </div>
    </Link>
  );
}
