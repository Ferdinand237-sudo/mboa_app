"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { validateEmail, validateTelephone } from "@/lib/utils/validators";
import { AuthHeader } from "@/components/auth/auth-header";
import { TextField, TextAreaField, FieldLabel } from "@/components/ui/text-field";
import { PersonIcon, EmailIcon, PhoneIcon, SendIcon, CheckIcon } from "@/components/ui/icons";

const ROLES = [
  {
    icon: "🏠",
    titre: "Propriétaire immobilier",
    description: "Je mets des logements en location",
  },
  {
    icon: "🛒",
    titre: "Commerçant / Boutique",
    description: "Je vends des produits depuis ma boutique",
  },
  {
    icon: "📦",
    titre: "Vendeur indépendant",
    description: "Je vends des articles sur la marketplace",
  },
  {
    icon: "🏠🛒",
    titre: "Propriétaire + Commerçant",
    description: "Je loue des logements ET je vends des produits",
  },
];

// Miroir de demande_vendeur_screen.dart : header dégradé ambré, bannière
// d'info, formulaire + sélecteur de rôle (4 cartes), écrit dans
// demandes_compte (traitée manuellement par un admin, comme sur mobile).
export default function RegisterVendeurPage() {
  const router = useRouter();
  const [nom, setNom] = useState("");
  const [email, setEmail] = useState("");
  const [whatsapp, setWhatsapp] = useState("");
  const [description, setDescription] = useState("");
  const [selectedRole, setSelectedRole] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);

    if (!nom.trim()) return setError("Le nom complet est requis");
    const emailError = validateEmail(email);
    if (emailError) return setError(emailError);
    const telError = validateTelephone(whatsapp);
    if (telError) return setError(telError);
    if (selectedRole === null) return setError("Veuillez sélectionner votre type d'activité");
    if (description.trim().length < 20) return setError("Description : minimum 20 caractères");

    setLoading(true);
    const supabase = createClient();
    const { error: insertError } = await supabase.from("demandes_compte").insert({
      nom: nom.trim(),
      email: email.trim(),
      whatsapp: whatsapp.trim(),
      type_activite: ROLES[selectedRole].titre,
      description: description.trim(),
    });
    setLoading(false);

    if (insertError) {
      setError("Erreur lors de l'envoi. Réessayez.");
      return;
    }
    setSuccess(true);
  }

  return (
    <div className="mx-auto max-w-md pb-12">
      <AuthHeader
        title="Compte Pro 🏪"
        subtitle="Remplis ce formulaire et notre équipe te contacte sous 24h"
        gradientClassName="from-[#92400E] to-mboa-secondary"
      />

      <form onSubmit={handleSubmit} className="flex flex-col gap-5 px-6 pt-6">
        <div className="flex items-start gap-2.5 rounded-mboa-md border border-mboa-primary/20 bg-mboa-primary/8 p-3.5">
          <span className="text-lg" aria-hidden>
            ℹ️
          </span>
          <p className="text-xs leading-relaxed text-mboa-primary">
            Un administrateur Mboa créera votre compte sur mesure et vous enverra vos identifiants
            de connexion sous 24h.
          </p>
        </div>

        {error && (
          <p className="rounded-mboa-md bg-mboa-danger/10 px-4 py-3 text-sm text-mboa-danger">{error}</p>
        )}

        <label className="flex flex-col gap-2">
          <FieldLabel>Nom complet</FieldLabel>
          <TextField
            type="text"
            required
            value={nom}
            onChange={(e) => setNom(e.target.value)}
            placeholder="Jean-Paul Mbassi"
            icon={<PersonIcon />}
          />
        </label>

        <label className="flex flex-col gap-2">
          <FieldLabel>Email</FieldLabel>
          <TextField
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="ton@email.com"
            icon={<EmailIcon />}
          />
        </label>

        <label className="flex flex-col gap-2">
          <FieldLabel>Numéro WhatsApp</FieldLabel>
          <TextField
            type="tel"
            required
            value={whatsapp}
            onChange={(e) => setWhatsapp(e.target.value)}
            placeholder="+237 6XX XXX XXX"
            icon={<PhoneIcon />}
          />
        </label>

        <div className="flex flex-col gap-3">
          <FieldLabel>Je veux publier des annonces</FieldLabel>
          {ROLES.map((role, i) => {
            const isSelected = selectedRole === i;
            return (
              <button
                key={role.titre}
                type="button"
                onClick={() => setSelectedRole(i)}
                className={`flex items-center gap-3 rounded-mboa-md border-[1.5px] p-3.5 text-left ${
                  isSelected
                    ? "border-2 border-mboa-secondary bg-mboa-secondary/8"
                    : "border-mboa-border bg-mboa-card"
                }`}
              >
                <span className="text-xl">{role.icon}</span>
                <span className="flex-1">
                  <span
                    className={`block text-[13px] font-bold ${
                      isSelected ? "text-mboa-secondary" : "text-mboa-text"
                    }`}
                  >
                    {role.titre}
                  </span>
                  <span className="mt-0.5 block text-xs text-mboa-text-muted">{role.description}</span>
                </span>
                <span
                  className={`flex h-[22px] w-[22px] shrink-0 items-center justify-center rounded-full border-2 ${
                    isSelected ? "border-mboa-secondary bg-mboa-secondary text-white" : "border-mboa-border"
                  }`}
                >
                  {isSelected && <CheckIcon />}
                </span>
              </button>
            );
          })}
        </div>

        <label className="flex flex-col gap-2">
          <FieldLabel>Décrivez votre activité</FieldLabel>
          <TextAreaField
            required
            rows={4}
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Ex: Je suis propriétaire de 3 chambres à Sangmelima et je vends aussi des meubles..."
          />
        </label>

        <button
          type="submit"
          disabled={loading}
          className="mt-2 flex h-[52px] items-center justify-center gap-2 rounded-mboa-lg bg-mboa-secondary text-sm font-bold text-white disabled:opacity-60"
        >
          {loading ? (
            <span className="h-5 w-5 animate-spin rounded-full border-2 border-white border-t-transparent" />
          ) : (
            <>
              <SendIcon className="h-[18px] w-[18px]" />
              Envoyer la demande
            </>
          )}
        </button>

        <button
          type="button"
          onClick={() => router.push("/")}
          className="text-center text-xs font-semibold text-mboa-primary"
        >
          Visiter l&apos;application sans compte →
        </button>
      </form>

      {success && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-6">
          <div className="w-full max-w-sm rounded-mboa-xl bg-mboa-card p-6 text-center">
            <span className="mx-auto flex h-20 w-20 items-center justify-center rounded-full bg-mboa-verified/10 text-4xl">
              ✅
            </span>
            <h2 className="mt-5 text-xl font-extrabold text-mboa-text">Demande envoyée !</h2>
            <p className="mt-3 text-[13px] leading-relaxed text-mboa-text-muted">
              Un administrateur Mboa va étudier votre demande et vous contacter sur WhatsApp ou email
              sous 24h avec vos identifiants de connexion.
            </p>
            <button
              onClick={() => router.push("/")}
              className="mt-6 flex h-[52px] w-full items-center justify-center rounded-mboa-lg bg-mboa-primary text-sm font-bold text-white"
            >
              Visiter l&apos;application
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
