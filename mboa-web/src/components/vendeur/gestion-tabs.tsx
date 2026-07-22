"use client";

import { useState } from "react";
import { AnnonceCard } from "@/components/vendeur/annonce-card";
import type { MonLogement, MonArticle } from "@/lib/data/vendeur-annonces";

function Vide({ emoji, message }: { emoji: string; message: string }) {
  return (
    <div className="flex flex-col items-center py-20 text-center">
      <span className="text-5xl" aria-hidden>
        {emoji}
      </span>
      <p className="mt-4 text-sm text-mboa-text-muted">{message}</p>
    </div>
  );
}

// Miroir du TabBar Logements/Articles (gestion_screen.dart) quand le compte
// cumule les deux sous-rôles.
export function GestionTabs({
  peutLogement,
  peutArticle,
  logements: initialLogements,
  articles: initialArticles,
}: {
  peutLogement: boolean;
  peutArticle: boolean;
  logements: MonLogement[];
  articles: MonArticle[];
}) {
  const [logements, setLogements] = useState(initialLogements);
  const [articles, setArticles] = useState(initialArticles);
  const [tab, setTab] = useState<"logements" | "articles">(peutLogement ? "logements" : "articles");

  const listeLogements =
    logements.length === 0 ? (
      <Vide emoji="🏠" message="Aucun logement publié" />
    ) : (
      <div className="flex flex-col gap-2.5">
        {logements.map((l) => (
          <AnnonceCard
            key={l.id}
            item={l}
            table="logements"
            detailHref={`/logements/${l.id}`}
            editHref={`/vendeur/logements/${l.id}/edit`}
            onRemoved={() => setLogements((prev) => prev.filter((x) => x.id !== l.id))}
          />
        ))}
      </div>
    );

  const listeArticles =
    articles.length === 0 ? (
      <Vide emoji="📦" message="Aucun article publié" />
    ) : (
      <div className="flex flex-col gap-2.5">
        {articles.map((a) => (
          <AnnonceCard
            key={a.id}
            item={a}
            table="articles"
            detailHref={`/marketplace/${a.id}`}
            editHref={`/vendeur/articles/${a.id}/edit`}
            onRemoved={() => setArticles((prev) => prev.filter((x) => x.id !== a.id))}
          />
        ))}
      </div>
    );

  if (peutLogement && !peutArticle) {
    return <div className="mx-auto max-w-2xl px-4 py-5 pb-10">{listeLogements}</div>;
  }
  if (peutArticle && !peutLogement) {
    return <div className="mx-auto max-w-2xl px-4 py-5 pb-10">{listeArticles}</div>;
  }

  return (
    <div>
      <div className="mx-auto flex max-w-2xl gap-1 border-b border-mboa-border px-4">
        <button
          type="button"
          onClick={() => setTab("logements")}
          className={`border-b-[3px] px-4 py-3 text-[13px] font-bold ${
            tab === "logements" ? "border-mboa-primary text-mboa-primary" : "border-transparent text-mboa-text-muted"
          }`}
        >
          🏠 Logements ({logements.length})
        </button>
        <button
          type="button"
          onClick={() => setTab("articles")}
          className={`border-b-[3px] px-4 py-3 text-[13px] font-bold ${
            tab === "articles" ? "border-mboa-primary text-mboa-primary" : "border-transparent text-mboa-text-muted"
          }`}
        >
          🛒 Articles ({articles.length})
        </button>
      </div>
      <div className="mx-auto max-w-2xl px-4 py-5 pb-10">
        {tab === "logements" ? listeLogements : listeArticles}
      </div>
    </div>
  );
}
