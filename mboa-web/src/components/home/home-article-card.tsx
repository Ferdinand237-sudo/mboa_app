import Link from "next/link";
import type { ArticleModel } from "@/lib/types/models";
import { formatPrix, photoPrincipale } from "@/lib/utils/format";
import { Photo } from "@/components/ui/photo";

// Miroir de _buildArticleCard dans home_screen.dart.
export function HomeArticleCard({ article }: { article: ArticleModel }) {
  return (
    <Link
      href={`/marketplace/${article.id}`}
      className="flex flex-col overflow-hidden rounded-mboa-lg bg-mboa-card shadow-sm transition-shadow hover:shadow-md"
    >
      <div className="relative aspect-[1.4/1] w-full overflow-hidden bg-gradient-to-br from-mboa-secondary/30 to-mboa-accent/20">
        <Photo src={photoPrincipale(article.photos)} alt={article.titre} />
        {article.boosted && (
          <span className="absolute left-2 top-2 rounded-mboa-full bg-mboa-boost px-2 py-0.5 text-[9px] font-bold text-white">
            🔥
          </span>
        )}
      </div>
      <div className="flex flex-col gap-0.5 px-2.5 py-2.5">
        <p className="truncate text-[11px] font-bold text-mboa-text">
          {article.titre}
        </p>
        <p className="text-[10px] font-semibold text-mboa-text-muted">
          {article.etat}
        </p>
        <p className="text-xs font-extrabold text-mboa-accent">
          {formatPrix(article.prix)}
        </p>
      </div>
    </Link>
  );
}
