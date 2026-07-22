import Link from "next/link";
import type { ArticleModel } from "@/lib/types/models";
import { formatPrix, photoPrincipale } from "@/lib/utils/format";
import { Photo } from "@/components/ui/photo";

// Miroir de _buildArticleCard dans market_screen.dart.
export function ArticleCard({ article }: { article: ArticleModel }) {
  return (
    <Link
      href={`/marketplace/${article.id}`}
      className="flex flex-col overflow-hidden rounded-mboa-lg bg-mboa-card shadow-sm transition-shadow hover:shadow-md"
    >
      <div className="relative aspect-square w-full overflow-hidden bg-gradient-to-br from-mboa-secondary/25 to-mboa-accent/15">
        <Photo src={photoPrincipale(article.photos)} alt={article.titre} />
        {article.boosted && (
          <span className="absolute left-1.5 top-1.5 rounded-mboa-full bg-mboa-boost px-2 py-0.5 text-[9px] font-bold text-white">
            🔥
          </span>
        )}
        {article.negociable && (
          <span className="absolute right-1.5 top-1.5 rounded-mboa-full bg-mboa-primary px-2 py-0.5 text-[9px] font-bold text-white">
            💬
          </span>
        )}
      </div>
      <div className="flex flex-1 flex-col gap-1 px-2 py-1.5">
        <p className="truncate text-[11px] font-bold text-mboa-text">
          {article.titre}
        </p>
        <p className="truncate text-[9px] font-semibold text-mboa-text-muted">
          {article.etat}
        </p>
        <p className="text-xs font-extrabold text-mboa-accent">
          {formatPrix(article.prix)}
        </p>
        <div className="flex items-center gap-1">
          <span className="truncate text-[9px] text-mboa-text-muted">
            👤 {article.vendeurNom ?? "Vendeur"}
          </span>
          {article.vendeurVerified && (
            <span className="shrink-0 text-[10px] text-mboa-verified">✓</span>
          )}
        </div>
        <span className="mt-0.5 block rounded-mboa-sm bg-mboa-primary py-1.5 text-center text-[10px] font-bold text-white">
          💬 Contacter
        </span>
      </div>
    </Link>
  );
}
