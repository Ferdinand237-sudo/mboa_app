import Link from "next/link";
import type { ArticleModel } from "@/lib/types/models";
import { formatPrix, photoPrincipale } from "@/lib/utils/format";
import { Badge } from "@/components/ui/badge";
import { Photo } from "@/components/ui/photo";

export function ArticleCard({ article }: { article: ArticleModel }) {
  return (
    <Link
      href={`/marketplace/${article.id}`}
      className="group flex flex-col overflow-hidden rounded-mboa-lg border border-mboa-border bg-mboa-card shadow-sm transition-shadow hover:shadow-md"
    >
      <div className="relative aspect-square w-full overflow-hidden">
        <Photo src={photoPrincipale(article.photos)} alt={article.titre} />
        {article.boosted && (
          <div className="absolute left-2 top-2">
            <Badge variant="boost">✦ Boosté</Badge>
          </div>
        )}
        <div className="absolute right-2 top-2">
          <Badge variant="neutral">{article.etat}</Badge>
        </div>
      </div>
      <div className="flex flex-1 flex-col gap-1.5 p-3.5">
        <h3 className="line-clamp-1 text-sm font-bold text-mboa-text">
          {article.titre}
        </h3>
        <p className="line-clamp-1 text-xs text-mboa-text-muted">
          {article.categorie}
        </p>
        <div className="mt-1 flex items-center justify-between">
          <span className="text-base font-extrabold text-mboa-accent">
            {formatPrix(article.prix)}
          </span>
          {article.negociable && (
            <span className="text-[11px] font-semibold text-mboa-text-muted">
              Négociable
            </span>
          )}
        </div>
      </div>
    </Link>
  );
}
