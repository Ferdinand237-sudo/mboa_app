"use client";

import { useState, type FormEvent } from "react";
import { createClient } from "@/lib/supabase/client";
import { PhotoPicker, type PhotoItem } from "@/components/vendeur/photo-picker";
import { ResultBanner } from "@/components/vendeur/result-banner";
import { Switch } from "@/components/ui/switch";
import { attendreDecisionModeration, messageResultatModeration, type ToneResultat } from "@/lib/utils/moderation";
import { PublishIcon } from "@/components/ui/icons";
import {
  CATEGORIES_MARKET,
  ETATS_ARTICLE,
  BUCKET_ARTICLES,
  MAX_PHOTOS_ARTICLE,
  MIN_PHOTOS_ARTICLE,
} from "@/lib/constants";

// Miroir de _FormArticle (publier_screen.dart).
export function FormArticle() {
  const [titre, setTitre] = useState("");
  const [description, setDescription] = useState("");
  const [prix, setPrix] = useState("");
  const [selectedCategorie, setSelectedCategorie] = useState(CATEGORIES_MARKET[0].label);
  const [selectedEtat, setSelectedEtat] = useState<string>(ETATS_ARTICLE[2]);
  const [negociable, setNegociable] = useState(false);
  const [accepteAvis, setAccepteAvis] = useState(false);
  const [newPhotos, setNewPhotos] = useState<{ file: File; preview: string }[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<{ message: string; tone: ToneResultat } | null>(null);
  const [loading, setLoading] = useState(false);
  const [analyseEnCours, setAnalyseEnCours] = useState(false);

  const photos: PhotoItem[] = newPhotos.map((p) => ({ kind: "new", preview: p.preview }));

  function ajouterPhoto(file: File) {
    if (newPhotos.length >= MAX_PHOTOS_ARTICLE) {
      setError(`Maximum ${MAX_PHOTOS_ARTICLE} photos`);
      return;
    }
    setNewPhotos((prev) => [...prev, { file, preview: URL.createObjectURL(file) }]);
  }

  function supprimerPhoto(index: number) {
    setNewPhotos((prev) => prev.filter((_, i) => i !== index));
  }

  async function uploadPhotos(userId: string): Promise<string[]> {
    const supabase = createClient();
    const timestamp = Date.now();
    return Promise.all(
      newPhotos.map(async ({ file }, i) => {
        const fileName = `${userId}/${timestamp}_${i}.jpg`;
        const { error: uploadError } = await supabase.storage
          .from(BUCKET_ARTICLES)
          .upload(fileName, file, { upsert: true });
        if (uploadError) throw uploadError;
        return supabase.storage.from(BUCKET_ARTICLES).getPublicUrl(fileName).data.publicUrl;
      }),
    );
  }

  async function publier(e: FormEvent) {
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
    if (newPhotos.length < MIN_PHOTOS_ARTICLE) {
      setError("Au moins 1 photo requise");
      return;
    }
    setError(null);
    setResult(null);
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
      const photoUrls = await uploadPhotos(user.id);
      const { data: inserted, error: insertError } = await supabase
        .from("articles")
        .insert({
          titre: titre.trim(),
          description: description.trim(),
          categorie: selectedCategorie,
          etat: selectedEtat,
          prix: prixNum,
          negociable,
          accepte_avis: accepteAvis,
          photos: photoUrls,
          vendeur_id: user.id,
          statut: "disponible",
          boosted: false,
          vues: 0,
          signalements: 0,
        })
        .select("id")
        .single();
      if (insertError) throw insertError;

      setAnalyseEnCours(true);
      const decision = await attendreDecisionModeration(supabase, "articles", inserted.id);
      setResult(messageResultatModeration(decision, "Article"));

      setTitre("");
      setDescription("");
      setPrix("");
      setSelectedCategorie(CATEGORIES_MARKET[0].label);
      setSelectedEtat(ETATS_ARTICLE[2]);
      setNegociable(false);
      setAccepteAvis(false);
      setNewPhotos([]);
    } catch {
      setError("Erreur lors de la publication. Réessaie.");
    } finally {
      setLoading(false);
      setAnalyseEnCours(false);
    }
  }

  return (
    <form onSubmit={publier} className="mx-auto flex max-w-lg flex-col gap-5 px-5 py-6 pb-12">
      {error && <ResultBanner message={error} tone="danger" />}
      {result && <ResultBanner message={result.message} tone={result.tone} />}

      <div>
        <p className="text-[13px] font-bold text-mboa-text">📷 Photos de l&apos;article</p>
        <p className="mt-1 text-xs text-mboa-text-muted">
          <span className="text-mboa-danger">Minimum 1 photo · </span>
          <span className="font-bold text-mboa-secondary">
            {newPhotos.length}/{MAX_PHOTOS_ARTICLE} ajoutées
          </span>
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
        <p className="mb-2 text-[13px] font-bold text-mboa-text">État de l&apos;article</p>
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
        <span className="text-[13px] font-bold text-mboa-text">Titre de l&apos;article</span>
        <input
          value={titre}
          onChange={(e) => setTitre(e.target.value)}
          placeholder="Ex: Lit 2 places + matelas en bon état"
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
            placeholder="15000"
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
          Autoriser les avis et notes sur cet article (utile pour un article vendu en série)
        </span>
      </label>

      <label className="flex flex-col gap-2">
        <span className="text-[13px] font-bold text-mboa-text">Description</span>
        <textarea
          rows={4}
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Décrivez l'article : dimensions, marque, raison de la vente..."
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
            {analyseEnCours ? "Analyse en cours..." : "Publication en cours..."}
          </>
        ) : (
          <>
            <PublishIcon className="h-5 w-5" />
            Publier l&apos;article
          </>
        )}
      </button>
    </form>
  );
}
