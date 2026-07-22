"use client";

import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Dialog } from "@/components/ui/dialog";
import { CrosshairIcon } from "@/components/ui/icons";
import { TYPES_JUSTIFICATIF, BUCKET_ATTESTATIONS } from "@/lib/constants";
import type { VisiteDetail } from "@/lib/data/ambassadeur";

// Miroir de AmbassadeurVisiteScreen (ambassadeur_visite_screen.dart). Le
// brouillon local + renvoi automatique à la reconnexion (SharedPreferences +
// Connectivity côté Flutter, pensés pour le terrain hors-réseau) n'ont pas
// d'équivalent web fiable sans service worker dédié : ici l'envoi échoue
// simplement avec un message si la connexion est coupée, à réessayer.
export function VisiteView({ verification }: { verification: VisiteDetail }) {
  const router = useRouter();
  const peutModifier = verification.statut === "assignee";

  if (!peutModifier) return <VisiteLectureSeule verification={verification} />;
  return <VisiteFormulaire verification={verification} onEnvoye={() => router.push("/ambassadeur/assignes")} />;
}

function VisiteLectureSeule({ verification }: { verification: VisiteDetail }) {
  const [attestationUrl, setAttestationUrl] = useState<string | null>(null);
  const [attestationError, setAttestationError] = useState<string | null>(null);

  async function voirAttestation() {
    setAttestationError(null);
    const supabase = createClient();
    try {
      const res = await supabase.functions.invoke("get-attestation-url", { body: { verificationId: verification.id } });
      const url = (res.data as { url?: string } | null)?.url;
      if (url) setAttestationUrl(url);
      else setAttestationError("Aucune attestation disponible");
    } catch {
      setAttestationError("Impossible de charger l'attestation");
    }
  }

  return (
    <div className="mx-auto max-w-lg px-5 py-6">
      <InfoLigne label="Statut" value={verification.statut} />
      {verification.conformiteBien != null && (
        <InfoLigne label="Bien conforme" value={verification.conformiteBien ? "Oui" : "Non"} />
      )}
      {verification.typeJustificatif && <InfoLigne label="Justificatif" value={verification.typeJustificatif} />}
      {verification.notes && <InfoLigne label="Notes" value={verification.notes} />}
      {verification.dateVisite && <InfoLigne label="Date de visite" value={verification.dateVisite} />}

      {verification.aUneAttestation && (
        <button
          type="button"
          onClick={voirAttestation}
          className="mt-2 rounded-mboa-md bg-mboa-primary px-4 py-2.5 text-sm font-bold text-white"
        >
          📄 Voir l&apos;attestation
        </button>
      )}
      {attestationError && <p className="mt-2 text-xs font-semibold text-mboa-danger">{attestationError}</p>}

      <Dialog open={attestationUrl !== null} onClose={() => setAttestationUrl(null)}>
        {attestationUrl && (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={attestationUrl} alt="Attestation" className="max-h-[70vh] w-full rounded-mboa-md object-contain" />
        )}
      </Dialog>
    </div>
  );
}

function InfoLigne({ label, value }: { label: string; value: string }) {
  return (
    <div className="mb-3">
      <p className="text-xs text-mboa-text-muted">{label}</p>
      <p className="text-sm font-semibold text-mboa-text">{value}</p>
    </div>
  );
}

function VisiteFormulaire({ verification, onEnvoye }: { verification: VisiteDetail; onEnvoye: () => void }) {
  const [conformite, setConformite] = useState<boolean | null>(null);
  const [typeJustificatif, setTypeJustificatif] = useState<string | null>(null);
  const [notes, setNotes] = useState("");
  const [lat, setLat] = useState<number | null>(null);
  const [lng, setLng] = useState<number | null>(null);
  const [gettingLocation, setGettingLocation] = useState(false);
  const [photo, setPhoto] = useState<{ file: File; preview: string } | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  function choisirPhoto(file: File | undefined) {
    if (!file) return;
    setPhoto({ file, preview: URL.createObjectURL(file) });
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
      () => {
        setError("Impossible d'obtenir la position");
        setGettingLocation(false);
      },
      { enableHighAccuracy: true, timeout: 15000 },
    );
  }

  async function soumettre() {
    if (conformite === null) {
      setError("Indique si le bien est conforme");
      return;
    }
    if (!typeJustificatif) {
      setError("Sélectionne le type de justificatif");
      return;
    }
    if (!photo) {
      setError("Ajoute une photo de l'attestation");
      return;
    }
    setError(null);
    setSubmitting(true);

    const supabase = createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      setSubmitting(false);
      return;
    }

    try {
      const fileName = `${user.id}/${verification.id}_${Date.now()}.jpg`;
      const { error: uploadError } = await supabase.storage
        .from(BUCKET_ATTESTATIONS)
        .upload(fileName, photo.file, { upsert: true });
      if (uploadError) throw uploadError;

      const { error: updateError } = await supabase
        .from("verifications_terrain")
        .update({
          conformite_bien: conformite,
          type_justificatif: typeJustificatif,
          notes: notes.trim(),
          lat,
          lng,
          attestation_path: fileName,
          statut: "visite_effectuee",
          date_visite: new Date().toISOString(),
        })
        .eq("id", verification.id);
      if (updateError) throw updateError;

      onEnvoye();
    } catch {
      setError("Erreur lors de l'envoi. Vérifie ta connexion et réessaie.");
      setSubmitting(false);
    }
  }

  return (
    <div className="mx-auto flex max-w-lg flex-col gap-5 px-5 py-6 pb-12">
      {error && <p className="rounded-mboa-md bg-mboa-danger/10 px-4 py-3 text-sm font-semibold text-mboa-danger">{error}</p>}

      <div>
        <p className="mb-2 text-[13px] font-bold text-mboa-text">✅ Conformité du bien</p>
        <div className="flex gap-2.5">
          <button
            type="button"
            onClick={() => setConformite(true)}
            className={`flex-1 rounded-mboa-lg border-[1.5px] py-3 text-[13px] font-bold ${
              conformite === true ? "border-mboa-verified bg-mboa-verified text-white" : "border-mboa-border bg-mboa-card text-mboa-text"
            }`}
          >
            Conforme
          </button>
          <button
            type="button"
            onClick={() => setConformite(false)}
            className={`flex-1 rounded-mboa-lg border-[1.5px] py-3 text-[13px] font-bold ${
              conformite === false ? "border-mboa-danger bg-mboa-danger text-white" : "border-mboa-border bg-mboa-card text-mboa-text"
            }`}
          >
            Non conforme
          </button>
        </div>
      </div>

      <div>
        <p className="mb-2 text-[13px] font-bold text-mboa-text">📄 Type de justificatif présenté</p>
        <div className="flex flex-wrap gap-2">
          {TYPES_JUSTIFICATIF.map((type) => {
            const isSelected = typeJustificatif === type;
            return (
              <button
                key={type}
                type="button"
                onClick={() => setTypeJustificatif(type)}
                className={`rounded-full border-[1.5px] px-3.5 py-2 text-xs font-semibold ${
                  isSelected ? "border-mboa-primary bg-mboa-primary text-white" : "border-mboa-border bg-mboa-card text-mboa-text"
                }`}
              >
                {type}
              </button>
            );
          })}
        </div>
      </div>

      <label className="flex flex-col gap-2">
        <span className="text-[13px] font-bold text-mboa-text">📝 Notes</span>
        <textarea
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          rows={3}
          placeholder="Observations complémentaires (optionnel)"
          className="w-full rounded-mboa-md border-[1.5px] border-mboa-border bg-mboa-background px-4 py-3.5 text-sm text-mboa-text outline-none focus:border-2 focus:border-mboa-primary"
        />
      </label>

      <div>
        <p className="mb-2 text-[13px] font-bold text-mboa-text">📍 Position de la visite</p>
        <button
          type="button"
          onClick={obtenirPosition}
          disabled={gettingLocation}
          className="flex items-center gap-2 rounded-mboa-md border-[1.5px] border-mboa-primary px-4 py-2.5 text-[13px] font-semibold text-mboa-primary disabled:opacity-60"
        >
          {gettingLocation ? (
            <span className="h-4 w-4 animate-spin rounded-full border-2 border-mboa-primary border-t-transparent" />
          ) : (
            <CrosshairIcon className="h-4.5 w-4.5" />
          )}
          {lat !== null ? "Position enregistrée ✓" : "Ma position"}
        </button>
      </div>

      <div>
        <p className="mb-2 text-[13px] font-bold text-mboa-text">📸 Photo/scan de l&apos;attestation</p>
        <button
          type="button"
          onClick={() => fileInputRef.current?.click()}
          className="flex h-40 w-full items-center justify-center overflow-hidden rounded-mboa-lg border-[1.5px] border-mboa-border bg-mboa-card"
        >
          {photo ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={photo.preview} alt="Attestation" className="h-full w-full object-cover" />
          ) : (
            <span className="flex flex-col items-center gap-2 text-mboa-text-muted">
              <span className="text-3xl">📷</span>
              <span className="text-sm">Prendre une photo</span>
            </span>
          )}
        </button>
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          capture="environment"
          className="hidden"
          onChange={(e) => choisirPhoto(e.target.files?.[0])}
        />
      </div>

      <button
        type="button"
        onClick={soumettre}
        disabled={submitting}
        className="mt-2 flex h-[52px] items-center justify-center rounded-mboa-lg bg-mboa-primary text-sm font-bold text-white disabled:opacity-60"
      >
        {submitting ? (
          <span className="h-5 w-5 animate-spin rounded-full border-2 border-white border-t-transparent" />
        ) : (
          "Envoyer la visite"
        )}
      </button>
    </div>
  );
}
