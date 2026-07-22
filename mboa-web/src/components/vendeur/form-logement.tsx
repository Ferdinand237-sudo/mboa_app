"use client";

import { useEffect, useState, type FormEvent } from "react";
import { createClient } from "@/lib/supabase/client";
import { PhotoPicker, type PhotoItem } from "@/components/vendeur/photo-picker";
import { ResultBanner } from "@/components/vendeur/result-banner";
import { attendreDecisionModeration, messageResultatModeration, type ToneResultat } from "@/lib/utils/moderation";
import { LocationIcon, CrosshairIcon, PublishIcon } from "@/components/ui/icons";
import {
  TYPES_LOGEMENT,
  EQUIPEMENTS,
  BUCKET_LOGEMENTS,
  DEFAULT_VILLE,
  MAX_PHOTOS_LOGEMENT,
  MIN_PHOTOS_LOGEMENT,
} from "@/lib/constants";

type LieuProche = { nom: string; distance: number };

function distanceMetres(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371000;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

function formatDistance(m: number): string {
  return m < 1000 ? `${Math.round(m)} m` : `${(m / 1000).toFixed(1)} km`;
}

// Miroir de _FormLogement (publier_screen.dart).
export function FormLogement({ compteActifPublication }: { compteActifPublication: boolean }) {
  const [titre, setTitre] = useState("");
  const [description, setDescription] = useState("");
  const [prix, setPrix] = useState("");
  const [surface, setSurface] = useState("");
  const [quartier, setQuartier] = useState("");
  const [selectedType, setSelectedType] = useState<string>(TYPES_LOGEMENT[0]);
  const [selectedEquipements, setSelectedEquipements] = useState<string[]>([]);
  const [newPhotos, setNewPhotos] = useState<{ file: File; preview: string }[]>([]);
  const [lat, setLat] = useState<number | null>(null);
  const [lng, setLng] = useState<number | null>(null);
  const [gettingLocation, setGettingLocation] = useState(false);
  const [lieuxPublics, setLieuxPublics] = useState<{ nom: string; lat: number; lng: number }[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<{ message: string; tone: ToneResultat } | null>(null);
  const [loading, setLoading] = useState(false);
  const [analyseEnCours, setAnalyseEnCours] = useState(false);

  useEffect(() => {
    const supabase = createClient();
    supabase
      .from("lieux_publics")
      .select("nom, lat, lng")
      .then(({ data }) => setLieuxPublics(data ?? []));
  }, []);

  const photos: PhotoItem[] = newPhotos.map((p) => ({ kind: "new", preview: p.preview }));

  function ajouterPhoto(file: File) {
    if (newPhotos.length >= MAX_PHOTOS_LOGEMENT) {
      setError(`Maximum ${MAX_PHOTOS_LOGEMENT} photos`);
      return;
    }
    setNewPhotos((prev) => [...prev, { file, preview: URL.createObjectURL(file) }]);
  }

  function supprimerPhoto(index: number) {
    setNewPhotos((prev) => prev.filter((_, i) => i !== index));
  }

  function obtenirPosition() {
    if (!navigator.geolocation) {
      setError("Géolocalisation non supportée par ce navigateur");
      return;
    }
    setGettingLocation(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setLat(pos.coords.latitude);
        setLng(pos.coords.longitude);
        setGettingLocation(false);
      },
      (err) => {
        if (err.code === err.PERMISSION_DENIED) {
          setError("Permission de localisation refusée");
        } else if (err.code === err.TIMEOUT) {
          setError("Signal GPS trop faible. Réessaie en extérieur ou près d'une fenêtre.");
        } else {
          setError("Erreur de localisation");
        }
        setGettingLocation(false);
      },
      { enableHighAccuracy: true, timeout: 15000 },
    );
  }

  const lieuxProches: LieuProche[] =
    lat !== null && lng !== null
      ? lieuxPublics
          .map((l) => ({ nom: l.nom, distance: distanceMetres(lat, lng, l.lat, l.lng) }))
          .sort((a, b) => a.distance - b.distance)
          .slice(0, 3)
      : [];

  async function uploadPhotos(userId: string): Promise<string[]> {
    const supabase = createClient();
    const timestamp = Date.now();
    return Promise.all(
      newPhotos.map(async ({ file }, i) => {
        const fileName = `${userId}/${timestamp}_${i}.jpg`;
        const { error: uploadError } = await supabase.storage
          .from(BUCKET_LOGEMENTS)
          .upload(fileName, file, { upsert: true });
        if (uploadError) throw uploadError;
        return supabase.storage.from(BUCKET_LOGEMENTS).getPublicUrl(fileName).data.publicUrl;
      }),
    );
  }

  async function publier(e: FormEvent) {
    e.preventDefault();
    if (!compteActifPublication) {
      setError("Vérification terrain en cours : publication indisponible pour le moment");
      return;
    }
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
    if (newPhotos.length < MIN_PHOTOS_LOGEMENT) {
      setError(`Minimum ${MIN_PHOTOS_LOGEMENT} photos requises`);
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
        .from("logements")
        .insert({
          titre: titre.trim(),
          description: description.trim(),
          type: selectedType,
          prix: prixNum,
          surface: surface.trim() ? parseFloat(surface.trim()) : null,
          photos: photoUrls,
          equipements: selectedEquipements,
          quartier: quartier.trim(),
          ville: DEFAULT_VILLE,
          lat,
          lng,
          proprietaire_id: user.id,
          statut: "disponible",
          boosted: false,
          vues: 0,
          signalements: 0,
          note_globale: 0,
          nb_avis: 0,
        })
        .select("id")
        .single();
      if (insertError) throw insertError;

      setAnalyseEnCours(true);
      const decision = await attendreDecisionModeration(supabase, "logements", inserted.id);
      setResult(messageResultatModeration(decision, "Logement"));

      setTitre("");
      setDescription("");
      setPrix("");
      setSurface("");
      setQuartier("");
      setSelectedType(TYPES_LOGEMENT[0]);
      setSelectedEquipements([]);
      setNewPhotos([]);
      setLat(null);
      setLng(null);
    } catch {
      setError("Erreur lors de la publication. Réessaie.");
    } finally {
      setLoading(false);
      setAnalyseEnCours(false);
    }
  }

  return (
    <form onSubmit={publier} className="mx-auto flex max-w-lg flex-col gap-5 px-5 py-6 pb-12">
      {!compteActifPublication && (
        <div className="flex items-start gap-2.5 rounded-mboa-lg border border-mboa-danger/30 bg-mboa-danger/8 p-3.5">
          <span aria-hidden>🛡</span>
          <p className="text-[12.5px] text-mboa-text">
            Vérification terrain en cours. Un ambassadeur Mboa doit visiter ton logement avant que tu
            puisses publier une annonce. Tu peux préparer ton annonce dès maintenant, la publication se
            débloquera automatiquement une fois la vérification validée par l&apos;administration.
          </p>
        </div>
      )}

      {error && <ResultBanner message={error} tone="danger" />}
      {result && <ResultBanner message={result.message} tone={result.tone} />}

      <div>
        <p className="text-[13px] font-bold text-mboa-text">📷 Photos du logement</p>
        <p className="mt-1 text-xs text-mboa-text-muted">
          <span className="text-mboa-danger">Minimum {MIN_PHOTOS_LOGEMENT} photos · </span>
          <span className="font-bold text-mboa-primary">
            {newPhotos.length}/{MAX_PHOTOS_LOGEMENT} ajoutées
          </span>
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
        <span className="text-[13px] font-bold text-mboa-text">Titre de l&apos;annonce</span>
        <input
          value={titre}
          onChange={(e) => setTitre(e.target.value)}
          placeholder="Ex: Chambre meublée proche campus IUT"
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
            placeholder="20000"
            className="min-w-0 rounded-mboa-md border-[1.5px] border-mboa-border bg-mboa-background px-4 py-3.5 text-sm text-mboa-text outline-none focus:border-2 focus:border-mboa-primary"
          />
        </label>
        <label className="flex flex-1 flex-col gap-2">
          <span className="text-[13px] font-bold text-mboa-text">Surface (m²)</span>
          <input
            inputMode="numeric"
            value={surface}
            onChange={(e) => setSurface(e.target.value)}
            placeholder="14"
            className="min-w-0 rounded-mboa-md border-[1.5px] border-mboa-border bg-mboa-background px-4 py-3.5 text-sm text-mboa-text outline-none focus:border-2 focus:border-mboa-primary"
          />
        </label>
      </div>

      <label className="flex flex-col gap-2">
        <span className="text-[13px] font-bold text-mboa-text">Quartier</span>
        <div className="flex items-center gap-2.5 rounded-mboa-md border-[1.5px] border-mboa-border bg-mboa-background px-4 focus-within:border-2 focus-within:border-mboa-primary">
          <LocationIcon className="h-5 w-5 shrink-0 text-mboa-text-muted" />
          <input
            value={quartier}
            onChange={(e) => setQuartier(e.target.value)}
            placeholder="Ex: Mvog-Ada"
            className="w-full min-w-0 bg-transparent py-3.5 text-sm text-mboa-text outline-none"
          />
        </div>
      </label>

      <div>
        <p className="mb-2 text-[13px] font-bold text-mboa-text">📍 Position GPS</p>
        <div className="rounded-mboa-lg border border-mboa-border bg-mboa-card p-3.5">
          {lat !== null && lng !== null && (
            <p className="mb-2.5 flex items-center gap-1.5 text-xs font-semibold text-mboa-text">
              <LocationIcon className="h-4 w-4 text-mboa-primary" />
              {lat.toFixed(5)}, {lng.toFixed(5)}
            </p>
          )}
          {lieuxProches.length > 0 && (
            <div className="mb-2.5 flex flex-wrap gap-1.5">
              {lieuxProches.map((l) => (
                <span
                  key={l.nom}
                  className="rounded-full bg-mboa-primary/8 px-2 py-1 text-[10px] font-semibold text-mboa-primary"
                >
                  📍 {l.nom} · {formatDistance(l.distance)}
                </span>
              ))}
            </div>
          )}
          <button
            type="button"
            onClick={obtenirPosition}
            disabled={gettingLocation}
            className="flex w-full items-center justify-center gap-2 rounded-mboa-md border-[1.5px] border-mboa-primary py-2.5 text-[13px] font-semibold text-mboa-primary disabled:opacity-60"
          >
            {gettingLocation ? (
              <span className="h-4 w-4 animate-spin rounded-full border-2 border-mboa-primary border-t-transparent" />
            ) : (
              <CrosshairIcon className="h-4.5 w-4.5" />
            )}
            {lat !== null ? "Actualiser ma position" : "Ma position"}
          </button>
        </div>
      </div>

      <label className="flex flex-col gap-2">
        <span className="text-[13px] font-bold text-mboa-text">Description</span>
        <textarea
          rows={4}
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Décrivez votre logement : état général, règles, disponibilité..."
          className="w-full rounded-mboa-md border-[1.5px] border-mboa-border bg-mboa-background px-4 py-3.5 text-sm text-mboa-text outline-none focus:border-2 focus:border-mboa-primary"
        />
      </label>

      <div>
        <p className="mb-2.5 text-[13px] font-bold text-mboa-text">Équipements disponibles</p>
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
        disabled={loading || !compteActifPublication}
        className="mt-2 flex h-[52px] items-center justify-center gap-2 rounded-mboa-lg bg-mboa-primary text-sm font-bold text-white disabled:opacity-60"
      >
        {loading ? (
          <>
            <span className="h-5 w-5 animate-spin rounded-full border-2 border-white border-t-transparent" />
            {analyseEnCours ? "Analyse en cours..." : "Publication en cours..."}
          </>
        ) : (
          <>
            <PublishIcon className="h-5 w-5" />
            Publier le logement
          </>
        )}
      </button>
    </form>
  );
}
