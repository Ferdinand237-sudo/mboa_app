import type { Metadata } from "next";
import { getArticles } from "@/lib/data/articles";
import { getCurrentUser } from "@/lib/data/auth";
import { MarketplaceClient } from "@/components/market/marketplace-client";

export const metadata: Metadata = {
  title: "Marketplace étudiant",
  description:
    "Achète et vends des équipements entre étudiants à Sangmelima : literie, mobilier, électronique, fournitures scolaires.",
};

export default async function MarketplacePage() {
  const [articles, user] = await Promise.all([
    getArticles({ limit: 200 }),
    getCurrentUser(),
  ]);

  return <MarketplaceClient initialArticles={articles} isLoggedIn={!!user} />;
}
