import Link from "next/link";
import type { LogementModel } from "@/lib/types/models";
import { formatPrix, photoPrincipale } from "@/lib/utils/format";
import { Photo } from "@/components/ui/photo";

// Miroir de _buildLogementCard dans home_screen.dart.
export function HomeLogementCard({ logement }: { logement: LogementModel }) {
  return (
    <Link
      href={`/logements/${logement.id}`}
      className="flex flex-col overflow-hidden rounded-mboa-lg bg-mboa-card shadow-sm transition-shadow hover:shadow-md"
    >
      <div className="relative aspect-[1.4/1] w-full overflow-hidden bg-gradient-to-br from-mboa-primary to-mboa-primary-light">
        <Photo src={photoPrincipale(logement.photos)} alt={logement.titre} />
        {logement.boosted && (
          <span className="absolute left-2 top-2 rounded-mboa-full bg-mboa-boost px-2 py-0.5 text-[9px] font-bold text-white">
            🔥 Boost
          </span>
        )}
        <span className="absolute right-2 top-2 flex h-7 w-7 items-center justify-center rounded-full bg-white/70 text-xs text-mboa-danger">
          ♡
        </span>
      </div>
      <div className="flex flex-col gap-0.5 px-2.5 py-2">
        <p className="truncate text-[11px] font-bold text-mboa-text">
          {logement.titre}
        </p>
        <p className="text-xs font-extrabold text-mboa-primary">
          {formatPrix(logement.prix)}
        </p>
        <p className="truncate text-[10px] text-mboa-text-muted">
          📍 {logement.quartier ?? "Sangmelima"}
        </p>
        <p className="text-[10px] text-mboa-text">
          ⭐ {logement.proprietaireNoteGlobale.toFixed(1)}
          <span className="text-mboa-text-muted">
            {" "}
            ({logement.proprietaireNbAvis})
          </span>
        </p>
      </div>
    </Link>
  );
}
