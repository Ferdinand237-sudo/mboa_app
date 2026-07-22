"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { validateTelephone } from "@/lib/utils/validators";
import { TextField, TextAreaField, FieldLabel } from "@/components/ui/text-field";
import { PhoneIcon, CheckIcon } from "@/components/ui/icons";

const ROLES = [
  { icon: "🏠", titre: "Propriétaire immobilier", description: "Je mets des logements en location" },
  { icon: "🛒", titre: "Commerçant / Boutique", description: "Je vends des produits depuis ma boutique" },
  { icon: "📦", titre: "Vendeur indépendant", description: "Je vends des articles sur la marketplace" },
];

// Miroir de devenir_contributeur_screen.dart.
export function DevenirContributeurForm({ dejaVendeur }: { dejaVendeur: boolean }) {
  const router = useRouter();
  const [selectedRole, setSelectedRole] = useState(-1);
  const [whatsapp, setWhatsapp] = useState("");
  const [description, setDescription] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [envoye, setEnvoye] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    const telError = validateTelephone(whatsapp);
    if (telError) {
      setError(telError);
      return;
    }
    if (!description.trim()) {
      setError("Requis");
      return;
    }
    if (selectedRole === -1) {
      setError("Sélectionne ton type d'activité");
      return;
    }
    setError(null);
    setLoading(true);

    const supabase = createClient();
    const {
      data: { user: authUser },
    } = await supabase.auth.getUser();
    if (!authUser) {
      setLoading(false);
      return;
    }

    try {
      const { data: profil } = await supabase.from("users").select("nom").eq("id", authUser.id).single();
      const { error: insertError } = await supabase.from("demandes_compte").insert({
        user_id: authUser.id,
        nom: profil?.nom ?? "",
        email: authUser.email,
        whatsapp: whatsapp.trim(),
        type_activite: ROLES[selectedRole].titre,
        description: description.trim(),
        statut: "en-attente",
      });
      if (insertError) throw insertError;
      setEnvoye(true);
    } catch {
      setError("Erreur lors de l'envoi. Réessayez.");
    } finally {
      setLoading(false);
    }
  }

  if (envoye) {
    return (
      <div className="mx-auto flex max-w-md flex-col items-center px-8 py-20 text-center">
        <span className="text-5xl" aria-hidden>
          ✅
        </span>
        <h2 className="mt-5 text-xl font-extrabold text-mboa-text">Demande envoyée !</h2>
        <p className="mt-2.5 text-sm leading-relaxed text-mboa-text-muted">
          L&apos;administrateur va examiner ta demande. Ton compte sera mis à jour automatiquement
          dès validation, avec les mêmes identifiants de connexion.
        </p>
        <button
          type="button"
          onClick={() => router.push("/profil")}
          className="mt-7 flex h-[52px] w-full items-center justify-center rounded-mboa-lg border-[1.5px] border-mboa-primary text-sm font-bold text-mboa-primary"
        >
          Retour au profil
        </button>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="mx-auto flex max-w-lg flex-col gap-5 px-6 pb-10">
      <p className="text-sm leading-relaxed text-mboa-text-muted">
        {dejaVendeur
          ? "Ajoute une nouvelle activité à ton compte existant : ton mot de passe ne change pas, l'administrateur ajoute simplement les permissions demandées."
          : "Deviens propriétaire ou vendeur sur Mboa : ton compte étudiant sera mis à niveau par l'administrateur, sans nouveau mot de passe."}
      </p>

      {error && (
        <p className="rounded-mboa-md bg-mboa-danger/10 px-4 py-3 text-sm text-mboa-danger">{error}</p>
      )}

      <div>
        <FieldLabel>Je suis...</FieldLabel>
        <div className="mt-3 flex flex-col gap-2.5">
          {ROLES.map((role, index) => {
            const isSelected = selectedRole === index;
            return (
              <button
                key={role.titre}
                type="button"
                onClick={() => setSelectedRole(index)}
                className={`flex items-center gap-3 rounded-mboa-md border p-3.5 text-left ${
                  isSelected ? "border-2 border-mboa-primary bg-mboa-primary/8" : "border-mboa-border bg-mboa-card"
                }`}
              >
                <span className="text-2xl" aria-hidden>
                  {role.icon}
                </span>
                <div className="flex-1">
                  <p className={`text-[13px] font-bold ${isSelected ? "text-mboa-primary" : "text-mboa-text"}`}>
                    {role.titre}
                  </p>
                  <p className="text-xs text-mboa-text-muted">{role.description}</p>
                </div>
                {isSelected && (
                  <span className="flex h-5 w-5 items-center justify-center rounded-full bg-mboa-primary text-white">
                    <CheckIcon />
                  </span>
                )}
              </button>
            );
          })}
        </div>
      </div>

      <label className="flex flex-col gap-2">
        <FieldLabel>WhatsApp</FieldLabel>
        <TextField
          type="tel"
          value={whatsapp}
          onChange={(e) => setWhatsapp(e.target.value)}
          placeholder="+237 6XX XXX XXX"
          icon={<PhoneIcon />}
        />
      </label>

      <label className="flex flex-col gap-2">
        <FieldLabel>Décris ton activité</FieldLabel>
        <TextAreaField
          rows={3}
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Ex : je loue 3 chambres près du campus IUT"
        />
      </label>

      <button
        type="submit"
        disabled={loading}
        className="mt-2 flex h-[52px] items-center justify-center rounded-mboa-lg bg-mboa-primary text-sm font-bold text-white disabled:opacity-60"
      >
        {loading ? (
          <span className="h-5 w-5 animate-spin rounded-full border-2 border-white border-t-transparent" />
        ) : (
          "Envoyer la demande"
        )}
      </button>
    </form>
  );
}
