import Link from "next/link";
import type { LogementModel } from "@/lib/types/models";
import { formatPrix, photoPrincipale } from "@/lib/utils/format";
import { Badge } from "@/components/ui/badge";
import { Photo } from "@/components/ui/photo";

// Miroir de _buildLogementTile dans logement_screen.dart.
export function LogementTile({ logement }: { logement: LogementModel }) {
  return (
    <Link
      href={`/logements/${logement.id}`}
      className="flex overflow-hidden rounded-mboa-lg bg-mboa-card shadow-sm transition-shadow hover:shadow-md"
    >
      <div className="relative h-[130px] w-[110px] shrink-0 overflow-hidden bg-gradient-to-br from-mboa-primary to-mboa-primary-light">
        <Photo src={photoPrincipale(logement.photos)} alt={logement.titre} />
        {logement.boosted && (
          <span className="absolute left-2 top-2 rounded-mboa-full bg-mboa-boost px-2 py-0.5 text-[9px] font-bold text-white">
            🔥
          </span>
        )}
      </div>

      <div className="flex-1 p-3.5">
        {(logement.boosted || logement.proprietaireVerified) && (
          <div className="mb-1.5 flex gap-1">
            {logement.boosted && <Badge variant="boost">🔥 Boost</Badge>}
            {logement.proprietaireVerified && (
              <Badge variant="verified">✅ Vérifié</Badge>
            )}
          </div>
        )}
        <p className="line-clamp-2 text-[13px] font-bold text-mboa-text">
          {logement.titre}
        </p>
        <p className="mt-1 text-xs text-mboa-text-muted">
          📍 {logement.quartier ?? "Sangmelima"}
        </p>
        <p className="mt-1.5 text-[15px] font-extrabold text-mboa-primary">
          {formatPrix(logement.prix)}
        </p>
        <p className="mt-1 text-xs text-mboa-text">
          ⭐ {logement.proprietaireNoteGlobale.toFixed(1)}
          <span className="text-mboa-text-muted">
            {" "}
            · {logement.surface ?? "?"}m²
          </span>
        </p>
      </div>

      <div className="flex items-center pr-3">
        <span className="text-xs text-mboa-text-muted">›</span>
      </div>
    </Link>
  );
}
