import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";
import { getArticleAModifier } from "@/lib/data/vendeur-annonces";
import { PageHeader } from "@/components/ui/page-header";
import { EditArticleForm } from "@/components/vendeur/edit-article-form";

export const metadata: Metadata = {
  title: "Modifier l'article",
};

// Miroir de edit_article_screen.dart.
export default async function EditArticlePage({ params }: { params: Promise<{ id: string }> }) {
  const user = await getCurrentUser();
  if (!user) redirect("/login");

  const { id } = await params;
  const article = await getArticleAModifier(id, user.id);
  if (!article) notFound();

  return (
    <div>
      <PageHeader title="✏️ Modifier l'article" />
      <EditArticleForm article={article} />
    </div>
  );
}
