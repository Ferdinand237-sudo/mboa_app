"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Dialog } from "@/components/ui/dialog";
import { Switch } from "@/components/ui/switch";
import type { VilleModel } from "@/lib/data/villes";

// Miroir de AdminVillesScreen (admin_villes_screen.dart) : liste des villes
// couvertes par Mboa, gérable sans republication de l'app ni redéploiement
// du site (table villes, RLS is_admin() — voir migration 20260727000000).
export function VillesClient({ villes: initialVilles }: { villes: VilleModel[] }) {
  const [villes, setVilles] = useState(initialVilles);
  const [dialogOuvert, setDialogOuvert] = useState(false);
  const [villeEnEdition, setVilleEnEdition] = useState<VilleModel | null>(null);

  async function recharger() {
    const supabase = createClient();
    const { data } = await supabase
      .from("villes")
      .select("id, nom, lat, lng, rayon_couverture_km, actif, ordre_affichage")
      .order("ordre_affichage");
    setVilles(
      (data ?? []).map((v) => ({
        id: String(v.id),
        nom: String(v.nom),
        lat: Number(v.lat),
        lng: Number(v.lng),
        rayonCouvertureKm: Number(v.rayon_couverture_km),
        actif: v.actif === true,
        ordreAffichage: Number(v.ordre_affichage),
      })),
    );
  }

  async function toggleActif(ville: VilleModel) {
    const supabase = createClient();
    await supabase.from("villes").update({ actif: !ville.actif }).eq("id", ville.id);
    await recharger();
  }

  function ouvrirAjout() {
    setVilleEnEdition(null);
    setDialogOuvert(true);
  }

  function ouvrirEdition(ville: VilleModel) {
    setVilleEnEdition(ville);
    setDialogOuvert(true);
  }

  return (
    <div className="mx-auto max-w-2xl px-4 py-6 sm:px-6">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-extrabold text-mboa-text">📍 Villes couvertes</h1>
        <button
          type="button"
          onClick={ouvrirAjout}
          className="rounded-mboa-md bg-mboa-primary px-4 py-2 text-sm font-bold text-white"
        >
          + Ajouter
        </button>
      </div>

      {villes.length === 0 ? (
        <p className="mt-8 text-center text-sm text-mboa-text-muted">Aucune ville pour le moment</p>
      ) : (
        <div className="mt-5 flex flex-col gap-3">
          {villes.map((v) => (
            <div key={v.id} className="flex items-center gap-3 rounded-mboa-lg bg-mboa-card p-4 shadow-sm">
              <button type="button" onClick={() => ouvrirEdition(v)} className="min-w-0 flex-1 text-left">
                <p className="text-sm font-bold text-mboa-text">{v.nom}</p>
                <p className="mt-1 text-xs text-mboa-text-muted">
                  {v.lat}, {v.lng} · rayon {v.rayonCouvertureKm}km · ordre {v.ordreAffichage}
                </p>
              </button>
              <Switch checked={v.actif} onChange={() => toggleActif(v)} />
            </div>
          ))}
        </div>
      )}

      {dialogOuvert && (
        <VilleDialog
          key={villeEnEdition?.id ?? "nouveau"}
          ville={villeEnEdition}
          prochainOrdre={villes.length}
          onClose={() => setDialogOuvert(false)}
          onSaved={recharger}
        />
      )}
    </div>
  );
}

// Remonté avec une key différente à chaque ouverture (nouvelle ville ou id
// différent) par VillesClient : les useState ci-dessous repartent toujours
// des bonnes valeurs sans logique de resynchronisation manuelle.
function VilleDialog({
  ville,
  prochainOrdre,
  onClose,
  onSaved,
}: {
  ville: VilleModel | null;
  prochainOrdre: number;
  onClose: () => void;
  onSaved: () => Promise<void>;
}) {
  const [nom, setNom] = useState(ville?.nom ?? "");
  const [lat, setLat] = useState(ville ? String(ville.lat) : "");
  const [lng, setLng] = useState(ville ? String(ville.lng) : "");
  const [rayon, setRayon] = useState(ville ? String(ville.rayonCouvertureKm) : "30");
  const [ordre, setOrdre] = useState(ville ? String(ville.ordreAffichage) : String(prochainOrdre));
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  function fermer() {
    setError(null);
    onClose();
  }

  async function enregistrer() {
    const latNum = parseFloat(lat.replace(",", "."));
    const lngNum = parseFloat(lng.replace(",", "."));
    const rayonNum = parseFloat(rayon.replace(",", ".")) || 30;
    const ordreNum = parseInt(ordre, 10) || 0;

    if (!nom.trim() || Number.isNaN(latNum) || Number.isNaN(lngNum)) {
      setError("Nom, latitude et longitude sont obligatoires");
      return;
    }
    setError(null);
    setLoading(true);
    const supabase = createClient();
    const valeurs = {
      nom: nom.trim(),
      lat: latNum,
      lng: lngNum,
      rayon_couverture_km: rayonNum,
      ordre_affichage: ordreNum,
    };
    const { error: dbError } = ville
      ? await supabase.from("villes").update(valeurs).eq("id", ville.id)
      : await supabase.from("villes").insert(valeurs);
    setLoading(false);
    if (dbError) {
      setError("Erreur lors de l'enregistrement");
      return;
    }
    await onSaved();
    fermer();
  }

  return (
    <Dialog open onClose={fermer}>
      <h2 className="text-base font-extrabold text-mboa-text">
        {ville ? `✏️ Modifier ${ville.nom}` : "📍 Ajouter une ville"}
      </h2>
      <div className="mt-3 flex flex-col gap-3">
        <Field label="Nom de la ville" value={nom} onChange={setNom} />
        <div className="flex gap-3">
          <Field label="Latitude" value={lat} onChange={setLat} type="text" />
          <Field label="Longitude" value={lng} onChange={setLng} type="text" />
        </div>
        <div className="flex gap-3">
          <Field label="Rayon de couverture (km)" value={rayon} onChange={setRayon} type="text" />
          <Field label="Ordre d'affichage" value={ordre} onChange={setOrdre} type="text" />
        </div>
      </div>
      {error && <p className="mt-3 text-xs font-semibold text-mboa-danger">{error}</p>}
      <div className="mt-5 flex justify-end gap-3">
        <button type="button" onClick={fermer} className="rounded-mboa-md px-4 py-2 text-sm font-semibold text-mboa-text-muted">
          Annuler
        </button>
        <button
          type="button"
          onClick={enregistrer}
          disabled={loading}
          className="rounded-mboa-md bg-mboa-primary px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
        >
          {loading ? "..." : ville ? "Enregistrer" : "Ajouter"}
        </button>
      </div>
    </Dialog>
  );
}

function Field({
  label,
  value,
  onChange,
  type = "text",
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  type?: string;
}) {
  return (
    <label className="flex min-w-0 flex-1 flex-col gap-1.5">
      <span className="text-xs font-semibold text-mboa-text">{label}</span>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full rounded-mboa-md border border-mboa-border bg-mboa-background px-3.5 py-2.5 text-sm text-mboa-text outline-none focus:border-2 focus:border-mboa-primary"
      />
    </label>
  );
}
