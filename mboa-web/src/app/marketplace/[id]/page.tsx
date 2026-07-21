import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getArticle } from "@/lib/data/articles";
import { getCurrentUser } from "@/lib/data/auth";
import { formatPrix, formatDateFr } from "@/lib/utils/format";
import { Gallery } from "@/components/ui/gallery";
import { Badge } from "@/components/ui/badge";
import { ContactCard } from "@/components/ui/contact-card";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ id: string }>;
}): Promise<Metadata> {
  const { id } = await params;
  const article = await getArticle(id);
  if (!article) return { title: "Article introuvable" };
  return {
    title: `${article.titre} — ${formatPrix(article.prix)}`,
    description: article.description.slice(0, 160),
  };
}

export default async function ArticleDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const [article, user] = await Promise.all([
    getArticle(id),
    getCurrentUser(),
  ]);

  if (!article) notFound();

  return (
    <div className="mx-auto max-w-6xl px-4 py-8 sm:px-6">
      <div className="grid gap-8 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <Gallery photos={article.photos} alt={article.titre} />

          <div className="mt-6 flex flex-wrap items-center gap-2">
            <Badge variant="neutral">{article.categorie}</Badge>
            <Badge variant="neutral">{article.etat}</Badge>
            {article.boosted && <Badge variant="boost">✦ Boosté</Badge>}
            {article.negociable && <Badge variant="neutral">Négociable</Badge>}
          </div>

          <h1 className="mt-3 text-2xl font-extrabold text-mboa-text sm:text-3xl">
            {article.titre}
          </h1>
          <p className="mt-3 text-2xl font-extrabold text-mboa-accent">
            {formatPrix(article.prix)}
          </p>

          <div className="mt-8">
            <h2 className="text-lg font-bold text-mboa-text">Description</h2>
            <p className="mt-2 whitespace-pre-line text-sm leading-relaxed text-mboa-text-muted">
              {article.description}
            </p>
          </div>

          <div className="mt-8 grid grid-cols-2 gap-4 text-sm text-mboa-text-muted sm:grid-cols-3">
            <div>👁 {article.vues} vues</div>
            <div>📅 Publié le {formatDateFr(article.datePublication)}</div>
          </div>
        </div>

        <aside className="lg:sticky lg:top-24 lg:h-fit">
          <ContactCard
            nom={article.vendeurNom ?? "Vendeur"}
            verified={article.vendeurVerified}
            note={article.vendeurNote}
            isLoggedIn={!!user}
          />
        </aside>
      </div>
    </div>
  );
}
