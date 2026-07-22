"use client";

import { useState } from "react";
import { FormLogement } from "@/components/vendeur/form-logement";
import { FormArticle } from "@/components/vendeur/form-article";

// Miroir du TabBar Logement/Article (publier_screen.dart) quand le compte
// cumule les deux sous-rôles.
export function PublierTabs({
  peutLogement,
  peutArticle,
  compteActifPublication,
}: {
  peutLogement: boolean;
  peutArticle: boolean;
  compteActifPublication: boolean;
}) {
  const [tab, setTab] = useState<"logement" | "article">(peutLogement ? "logement" : "article");

  if (peutLogement && !peutArticle) return <FormLogement compteActifPublication={compteActifPublication} />;
  if (peutArticle && !peutLogement) return <FormArticle />;

  return (
    <div>
      <div className="mx-auto flex max-w-lg gap-1 border-b border-mboa-border px-5">
        <button
          type="button"
          onClick={() => setTab("logement")}
          className={`border-b-[3px] px-4 py-3 text-[13px] font-bold ${
            tab === "logement" ? "border-mboa-primary text-mboa-primary" : "border-transparent text-mboa-text-muted"
          }`}
        >
          🏠 Logement
        </button>
        <button
          type="button"
          onClick={() => setTab("article")}
          className={`border-b-[3px] px-4 py-3 text-[13px] font-bold ${
            tab === "article" ? "border-mboa-primary text-mboa-primary" : "border-transparent text-mboa-text-muted"
          }`}
        >
          🛒 Article
        </button>
      </div>
      {tab === "logement" ? (
        <FormLogement compteActifPublication={compteActifPublication} />
      ) : (
        <FormArticle />
      )}
    </div>
  );
}
