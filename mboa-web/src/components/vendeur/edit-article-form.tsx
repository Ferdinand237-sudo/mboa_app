"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { PhotoPicker, type PhotoItem } from "@/components/vendeur/photo-picker";
import { ResultBanner } from "@/components/vendeur/result-banner";
import { Switch } from "@/components/ui/switch";
import { SaveIcon } from "@/components/ui/icons";
import { CATEGORIES_MARKET, ETATS_ARTICLE, BUCKET_ARTICLES, MAX_PHOTOS_ARTICLE, MIN_PHOTOS_ARTICLE } from "@/lib/constants";
import type { ArticleAModifier } from "@/lib/data/vendeur-annonces";

// Miroir de edit_article_screen.dart.
export function EditArticleForm({ article }: { article: ArticleAModifier }) {
  const router = useRouter();
  const [titre, setTitre] = useState(article.titre);
  const [description, setDescription] = useState(article.description);
  const [prix, setPrix] = useState(String(article.prix));
  const [selectedCategorie, setSelectedCategorie] = useState(article.categorie);
  const [selectedEtat, setSelectedEtat] = useState(article.etat);
  const [negociable, setNegociable] = useState(article.negociable);
  const [accepteAvis, setAccepteAvis] = useState(article.accepteAvis);
  const [existingPhotos, setExistingPhotos] = useState<string[]>(article.photos);
  const [newPhotos, setNewPhotos] = useState<{ file: File; preview: string }[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const totalPhotos = existingPhotos.length + newPhotos.length;
  const photos: PhotoItem[] = [
    ...existingPhotos.map((url) => ({ kind: "existing" as const, url })),
    ...newPhotos.map((p) => ({ kind: "new" as const, preview: p.preview })),
  ];

  function ajouterPhoto(file: File) {
    if (totalPhotos >= MAX_PHOTOS_ARTICLE) {
      setError(`Maximum ${MAX_PHOTOS_ARTICLE} photos`);
      return;
    }
    setNewPhotos((prev) => [...prev, { file, preview: URL.createObjectURL(file) }]);
  }

  function supprimerPhoto(index: number) {
    if (index < existingPhotos.length) {
      setExistingPhotos((prev) => prev.filter((_, i) => i !== index));
    } else {
      const i = index - existingPhotos.length;
      setNewPhotos((prev) => prev.filter((_, j) => j !== i));
    }
  }

  async function enregistrer(e: FormEvent) {
    e.preventDefault();
    if (!titre.trim()) {
      setError("Le titre est requis");
      return;
    }
    const prixNum = parseInt(prix.trim().replace(/\s/g, ""), 10);
    if (!prix.trim() || Number.isNaN(prixNum)) {
      setError("Prix invalide");
      return;
    }
    if (description.trim().length < 20) {
      setError("La description doit contenir au moins 20 caractères");
      return;
    }
    if (totalPhotos < MIN_PHOTOS_ARTICLE) {
      setError("Au moins 1 photo requise");
      return;
    }
    setError(null);
    setLoading(true);

    const supabase = createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      setLoading(false);
      return;
    }

    try {
      const timestamp = Date.now();
      const nouvellesUrls = await Promise.all(
        newPhotos.map(async ({ file }, i) => {
          const fileName = `${user.id}/${timestamp}_${i}.jpg`;
          const { error: uploadError } = await supabase.storage
            .from(BUCKET_ARTICLES)
            .upload(fileName, file, { upsert: true });
          if (uploadError) throw uploadError;
          return supabase.storage.from(BUCKET_ARTICLES).getPublicUrl(fileName).data.publicUrl;
        }),
      );

      const { error: updateError } = await supabase
        .from("articles")
        .update({
          titre: titre.trim(),
          description: description.trim(),
          categorie: selectedCategorie,
          etat: selectedEtat,
          prix: prixNum,
          negociable,
          accepte_avis: accepteAvis,
          photos: [...existingPhotos, ...nouvellesUrls],
        })
        .eq("id", article.id);
      if (updateError) throw updateError;

      router.push("/vendeur/annonces");
      router.refresh();
    } catch {
      setError("Erreur lors de l'enregistrement. Réessaie.");
      setLoading(false);
    }
  }

  return (
    <form onSubmit={enregistrer} className="mx-auto flex max-w-lg flex-col gap-5 px-5 py-6 pb-12">
      {error && <ResultBanner message={error} tone="danger" />}

      <div>
        <p className="text-[13px] font-bold text-mboa-text">📷 Photos</p>
        <p className="mt-1 text-xs text-mboa-text-muted">
          {totalPhotos}/{MAX_PHOTOS_ARTICLE} photos
        </p>
        <div className="mt-3">
          <PhotoPicker
            photos={photos}
            max={MAX_PHOTOS_ARTICLE}
            variant="secondary"
            onAdd={ajouterPhoto}
            onRemove={supprimerPhoto}
          />
        </div>
      </div>

      <div>
        <p className="mb-2 text-[13px] font-bold text-mboa-text">Catégorie</p>
        <div className="flex gap-2 overflow-x-auto pb-1">
          {CATEGORIES_MARKET.map((cat) => {
            const isSelected = selectedCategorie === cat.label;
            return (
              <button
                key={cat.label}
                type="button"
                onClick={() => setSelectedCategorie(cat.label)}
                className={`flex shrink-0 items-center gap-1.5 rounded-full border-[1.5px] px-3.5 py-1.5 text-xs font-semibold ${
                  isSelected
                    ? "border-mboa-secondary bg-mboa-secondary text-white"
                    : "border-mboa-border bg-mboa-card text-mboa-text"
                }`}
              >
                <span>{cat.icon}</span>
                {cat.label}
              </button>
            );
          })}
        </div>
      </div>

      <div>
        <p className="mb-2 text-[13px] font-bold text-mboa-text">État</p>
        <div className="flex flex-wrap gap-2">
          {ETATS_ARTICLE.map((etat) => {
            const isSelected = selectedEtat === etat;
            return (
              <button
                key={etat}
                type="button"
                onClick={() => setSelectedEtat(etat)}
                className={`rounded-full border-[1.5px] px-3.5 py-2 text-xs font-semibold ${
                  isSelected
                    ? "border-mboa-accent bg-mboa-accent text-white"
                    : "border-mboa-border bg-mboa-card text-mboa-text"
                }`}
              >
                {etat}
              </button>
            );
          })}
        </div>
      </div>

      <label className="flex flex-col gap-2">
        <span className="text-[13px] font-bold text-mboa-text">Titre</span>
        <input
          value={titre}
          onChange={(e) => setTitre(e.target.value)}
          className="rounded-mboa-md border-[1.5px] border-mboa-border bg-mboa-background px-4 py-3.5 text-sm text-mboa-text outline-none focus:border-2 focus:border-mboa-primary"
        />
      </label>

      <div>
        <p className="mb-2 text-[13px] font-bold text-mboa-text">Prix (FCFA)</p>
        <div className="flex items-center gap-4">
          <input
            inputMode="numeric"
            value={prix}
            onChange={(e) => setPrix(e.target.value)}
            className="min-w-0 flex-1 rounded-mboa-md border-[1.5px] border-mboa-border bg-mboa-background px-4 py-3.5 text-sm text-mboa-text outline-none focus:border-2 focus:border-mboa-primary"
          />
          <label className="flex shrink-0 items-center gap-2">
            <Switch checked={negociable} onChange={setNegociable} />
            <span className="text-xs font-semibold text-mboa-text">Négociable</span>
          </label>
        </div>
      </div>

      <label className="flex items-center gap-3">
        <Switch checked={accepteAvis} onChange={setAccepteAvis} />
        <span className="text-xs font-semibold text-mboa-text">
          Autoriser les avis et notes sur cet article
        </span>
      </label>

      <label className="flex flex-col gap-2">
        <span className="text-[13px] font-bold text-mboa-text">Description</span>
        <textarea
          rows={4}
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          className="w-full rounded-mboa-md border-[1.5px] border-mboa-border bg-mboa-background px-4 py-3.5 text-sm text-mboa-text outline-none focus:border-2 focus:border-mboa-primary"
        />
      </label>

      <button
        type="submit"
        disabled={loading}
        className="mt-2 flex h-[52px] items-center justify-center gap-2 rounded-mboa-lg bg-mboa-secondary text-sm font-bold text-white disabled:opacity-60"
      >
        {loading ? (
          <>
            <span className="h-5 w-5 animate-spin rounded-full border-2 border-white border-t-transparent" />
            Enregistrement...
          </>
        ) : (
          <>
            <SaveIcon className="h-5 w-5" />
            Enregistrer les modifications
          </>
        )}
      </button>
    </form>
  );
}
