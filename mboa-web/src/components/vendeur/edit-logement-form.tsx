"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { PhotoPicker, type PhotoItem } from "@/components/vendeur/photo-picker";
import { ResultBanner } from "@/components/vendeur/result-banner";
import { SaveIcon } from "@/components/ui/icons";
import { TYPES_LOGEMENT, EQUIPEMENTS, BUCKET_LOGEMENTS, MAX_PHOTOS_LOGEMENT, MIN_PHOTOS_LOGEMENT } from "@/lib/constants";
import type { LogementAModifier } from "@/lib/data/vendeur-annonces";

// Miroir de edit_logement_screen.dart.
export function EditLogementForm({ logement }: { logement: LogementAModifier }) {
  const router = useRouter();
  const [titre, setTitre] = useState(logement.titre);
  const [description, setDescription] = useState(logement.description);
  const [prix, setPrix] = useState(String(logement.prix));
  const [surface, setSurface] = useState(logement.surface != null ? String(logement.surface) : "");
  const [quartier, setQuartier] = useState(logement.quartier ?? "");
  const [selectedType, setSelectedType] = useState(logement.type);
  const [selectedEquipements, setSelectedEquipements] = useState<string[]>(logement.equipements);
  const [existingPhotos, setExistingPhotos] = useState<string[]>(logement.photos);
  const [newPhotos, setNewPhotos] = useState<{ file: File; preview: string }[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const totalPhotos = existingPhotos.length + newPhotos.length;
  const photos: PhotoItem[] = [
    ...existingPhotos.map((url) => ({ kind: "existing" as const, url })),
    ...newPhotos.map((p) => ({ kind: "new" as const, preview: p.preview })),
  ];

  function ajouterPhoto(file: File) {
    if (totalPhotos >= MAX_PHOTOS_LOGEMENT) {
      setError(`Maximum ${MAX_PHOTOS_LOGEMENT} photos`);
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
    if (!quartier.trim()) {
      setError("Le quartier est requis");
      return;
    }
    if (description.trim().length < 20) {
      setError("La description doit contenir au moins 20 caractères");
      return;
    }
    if (totalPhotos < MIN_PHOTOS_LOGEMENT) {
      setError(`Minimum ${MIN_PHOTOS_LOGEMENT} photos requises`);
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
            .from(BUCKET_LOGEMENTS)
            .upload(fileName, file, { upsert: true });
          if (uploadError) throw uploadError;
          return supabase.storage.from(BUCKET_LOGEMENTS).getPublicUrl(fileName).data.publicUrl;
        }),
      );

      const { error: updateError } = await supabase
        .from("logements")
        .update({
          titre: titre.trim(),
          description: description.trim(),
          type: selectedType,
          prix: prixNum,
          surface: surface.trim() ? parseFloat(surface.trim()) : null,
          photos: [...existingPhotos, ...nouvellesUrls],
          equipements: selectedEquipements,
          quartier: quartier.trim(),
        })
        .eq("id", logement.id);
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
          {totalPhotos}/{MAX_PHOTOS_LOGEMENT} photos
        </p>
        <div className="mt-3">
          <PhotoPicker
            photos={photos}
            max={MAX_PHOTOS_LOGEMENT}
            variant="primary"
            onAdd={ajouterPhoto}
            onRemove={supprimerPhoto}
          />
        </div>
      </div>

      <div>
        <p className="mb-2 text-[13px] font-bold text-mboa-text">Type de logement</p>
        <div className="flex gap-2.5">
          {TYPES_LOGEMENT.map((type) => {
            const isSelected = selectedType === type;
            return (
              <button
                key={type}
                type="button"
                onClick={() => setSelectedType(type)}
                className={`flex-1 rounded-xl border-[1.5px] py-3 text-xs font-bold ${
                  isSelected
                    ? "border-mboa-primary bg-mboa-primary text-white"
                    : "border-mboa-border bg-mboa-card text-mboa-text"
                }`}
              >
                {type}
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

      <div className="flex gap-3">
        <label className="flex flex-1 flex-col gap-2">
          <span className="text-[13px] font-bold text-mboa-text">Prix / mois (FCFA)</span>
          <input
            inputMode="numeric"
            value={prix}
            onChange={(e) => setPrix(e.target.value)}
            className="min-w-0 rounded-mboa-md border-[1.5px] border-mboa-border bg-mboa-background px-4 py-3.5 text-sm text-mboa-text outline-none focus:border-2 focus:border-mboa-primary"
          />
        </label>
        <label className="flex flex-1 flex-col gap-2">
          <span className="text-[13px] font-bold text-mboa-text">Surface (m²)</span>
          <input
            inputMode="numeric"
            value={surface}
            onChange={(e) => setSurface(e.target.value)}
            className="min-w-0 rounded-mboa-md border-[1.5px] border-mboa-border bg-mboa-background px-4 py-3.5 text-sm text-mboa-text outline-none focus:border-2 focus:border-mboa-primary"
          />
        </label>
      </div>

      <label className="flex flex-col gap-2">
        <span className="text-[13px] font-bold text-mboa-text">Quartier</span>
        <input
          value={quartier}
          onChange={(e) => setQuartier(e.target.value)}
          className="rounded-mboa-md border-[1.5px] border-mboa-border bg-mboa-background px-4 py-3.5 text-sm text-mboa-text outline-none focus:border-2 focus:border-mboa-primary"
        />
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

      <div>
        <p className="mb-2.5 text-[13px] font-bold text-mboa-text">Équipements</p>
        <div className="flex flex-wrap gap-2">
          {EQUIPEMENTS.map((eq) => {
            const isSelected = selectedEquipements.includes(eq.label);
            return (
              <button
                key={eq.label}
                type="button"
                onClick={() =>
                  setSelectedEquipements((prev) =>
                    isSelected ? prev.filter((l) => l !== eq.label) : [...prev, eq.label],
                  )
                }
                className={`rounded-full border-[1.5px] px-3.5 py-2 text-xs font-semibold ${
                  isSelected
                    ? "border-mboa-primary bg-mboa-primary text-white"
                    : "border-mboa-border bg-mboa-card text-mboa-text"
                }`}
              >
                {isSelected ? `✓  ${eq.label}` : `${eq.icon}  ${eq.label}`}
              </button>
            );
          })}
        </div>
      </div>

      <button
        type="submit"
        disabled={loading}
        className="mt-2 flex h-[52px] items-center justify-center gap-2 rounded-mboa-lg bg-mboa-primary text-sm font-bold text-white disabled:opacity-60"
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
