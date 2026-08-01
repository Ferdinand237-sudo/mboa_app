"use client";

import { useState, useEffect, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { validateEmail, validateTelephone, validateMotDePasse } from "@/lib/utils/validators";
import { lireCodeParrainStocke } from "@/lib/utils/referral";
import type { VilleModel } from "@/lib/data/villes";
import { AuthHeader } from "@/components/auth/auth-header";
import { TextField, TextAreaField, FieldLabel } from "@/components/ui/text-field";
import { PersonIcon, EmailIcon, PhoneIcon, LockIcon, EyeIcon, EyeOffIcon, SendIcon, CheckIcon } from "@/components/ui/icons";

const ROLES = [
  {
    icon: "🏠",
    titre: "Propriétaire immobilier",
    description: "Je mets des logements en location",
    sousRoles: ["proprietaire"],
  },
  {
    icon: "🛒",
    titre: "Commerçant / Boutique",
    description: "Je vends des produits depuis ma boutique",
    sousRoles: ["commercant"],
  },
  {
    icon: "📦",
    titre: "Vendeur indépendant",
    description: "Je vends des articles sur la marketplace",
    sousRoles: ["vendeur_independant"],
  },
  {
    icon: "🏠🛒",
    titre: "Propriétaire + Commerçant",
    description: "Je loue des logements ET je vends des produits",
    sousRoles: ["proprietaire", "commercant"],
  },
] as const;

// Miroir de demande_vendeur_screen.dart : header dégradé ambré, bannière
// d'info, formulaire + sélecteur de rôle (4 cartes) + ville + mot de passe.
// Le candidat crée directement son compte (supabase.auth.signUp, comme
// register/etudiant) au lieu de laisser un admin lui en inventer un —
// sa demande a donc systématiquement un user_id, et l'admin n'a plus qu'à
// valider en un clic (catégorie/ville déjà choisies, voir
// create-vendor-dialog.tsx). Le mot de passe ne transite jamais par
// demandes_compte, uniquement par le mécanisme Auth standard.
export default function RegisterVendeurPage() {
  const router = useRouter();
  const [nom, setNom] = useState("");
  const [email, setEmail] = useState("");
  const [whatsapp, setWhatsapp] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [description, setDescription] = useState("");
  const [selectedRole, setSelectedRole] = useState<number | null>(null);
  const [villes, setVilles] = useState<VilleModel[]>([]);
  const [selectedVille, setSelectedVille] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    // Requête directe côté client (comme form-logement.tsx) : getVilles()
    // dépend de next/headers, réservé aux Server Components.
    const supabase = createClient();
    supabase
      .from("villes")
      .select("id, nom, lat, lng, rayon_couverture_km, actif, ordre_affichage")
      .eq("actif", true)
      .order("ordre_affichage")
      .then(({ data }) => {
        const v: VilleModel[] = (data ?? []).map((row) => ({
          id: String(row.id),
          nom: String(row.nom),
          lat: Number(row.lat),
          lng: Number(row.lng),
          rayonCouvertureKm: Number(row.rayon_couverture_km),
          actif: true,
          ordreAffichage: Number(row.ordre_affichage),
        }));
        setVilles(v);
        if (v.length > 0) setSelectedVille((prev) => prev || v[0].nom);
      });
  }, []);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);

    if (!nom.trim()) return setError("Le nom complet est requis");
    const emailError = validateEmail(email);
    if (emailError) return setError(emailError);
    const telError = validateTelephone(whatsapp);
    if (telError) return setError(telError);
    const passError = validateMotDePasse(password);
    if (passError) return setError(passError);
    if (password !== confirmPassword) return setError("Les mots de passe ne correspondent pas");
    if (selectedRole === null) return setError("Veuillez sélectionner votre type d'activité");
    if (!selectedVille) return setError("Veuillez sélectionner votre ville");
    if (description.trim().length < 20) return setError("Description : minimum 20 caractères");

    setLoading(true);
    const supabase = createClient();

    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: email.trim(),
      password,
      options: {
        emailRedirectTo: `${window.location.origin}/login`,
        data: { nom: nom.trim(), telephone: whatsapp.trim(), role: "visiteur" },
      },
    });

    if (authError || !authData.user) {
      setError(authError?.message ?? "Erreur lors de la création du compte");
      setLoading(false);
      return;
    }

    // La ville de profil sert de repli à la publication (GPS prioritaire
    // pour un logement, aucun GPS pour un article) — voir publier_screen.dart
    // / form-logement.tsx / form-article.tsx.
    await supabase.from("users").update({ ville: selectedVille }).eq("id", authData.user.id);

    const { error: insertError } = await supabase.from("demandes_compte").insert({
      user_id: authData.user.id,
      nom: nom.trim(),
      email: email.trim(),
      whatsapp: whatsapp.trim(),
      type_activite: ROLES[selectedRole].titre,
      sous_roles_demandees: ROLES[selectedRole].sousRoles,
      ville: selectedVille,
      description: description.trim(),
      // Repris par l'admin à l'approbation, pour créditer le parrain
      // (migration 20260731000000_parrainage.sql).
      code_parrain: lireCodeParrainStocke(),
    });
    setLoading(false);

    if (insertError) {
      setError("Compte créé, mais erreur lors de l'envoi de la demande. Contacte l'administration.");
      return;
    }
    setSuccess(true);
  }

  if (success) {
    return (
      <div className="mx-auto flex min-h-[70vh] max-w-md flex-col items-center justify-center px-6 text-center">
        <span className="mx-auto flex h-20 w-20 items-center justify-center rounded-full bg-mboa-verified/10 text-4xl">
          ✅
        </span>
        <h1 className="mt-5 text-xl font-extrabold text-mboa-text">Compte créé, demande envoyée !</h1>
        <p className="mt-3 text-[13px] leading-relaxed text-mboa-text-muted">
          Tu peux déjà te connecter avec ton email et ton mot de passe. Un administrateur Mboa va
          étudier ta demande Pro et l&apos;activer sous 24h.
        </p>
        <button
          onClick={() => router.push("/login")}
          className="mt-6 flex h-[52px] w-full items-center justify-center rounded-mboa-lg bg-mboa-primary text-sm font-bold text-white"
        >
          Me connecter
        </button>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-md pb-12">
      <AuthHeader
        title="Compte Pro 🏪"
        subtitle="Crée ton compte, notre équipe valide ta demande sous 24h"
        gradientClassName="from-[#92400E] to-mboa-secondary"
      />

      <form onSubmit={handleSubmit} className="flex flex-col gap-5 px-6 pt-6">
        <div className="flex items-start gap-2.5 rounded-mboa-md border border-mboa-primary/20 bg-mboa-primary/8 p-3.5">
          <span className="text-lg" aria-hidden>
            ℹ️
          </span>
          <p className="text-xs leading-relaxed text-mboa-primary">
            Ton compte est créé immédiatement avec le mot de passe que tu choisis ici. Un
            administrateur Mboa valide ensuite ta demande Pro, généralement sous 24h.
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

        <label className="flex flex-col gap-2">
          <FieldLabel>Mot de passe</FieldLabel>
          <TextField
            type={showPassword ? "text" : "password"}
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            icon={<LockIcon />}
            suffix={
              <button
                type="button"
                onClick={() => setShowPassword((v) => !v)}
                aria-label={showPassword ? "Masquer le mot de passe" : "Afficher le mot de passe"}
                className="shrink-0 text-mboa-text-muted"
              >
                {showPassword ? <EyeOffIcon /> : <EyeIcon />}
              </button>
            }
          />
        </label>

        <label className="flex flex-col gap-2">
          <FieldLabel>Confirmer le mot de passe</FieldLabel>
          <TextField
            type={showPassword ? "text" : "password"}
            required
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            placeholder="••••••••"
            icon={<LockIcon />}
          />
        </label>

        <label className="flex flex-col gap-2">
          <FieldLabel>Ta ville</FieldLabel>
          <select
            required
            value={selectedVille}
            onChange={(e) => setSelectedVille(e.target.value)}
            className="h-[52px] rounded-mboa-lg border border-mboa-border bg-mboa-card px-3.5 text-sm text-mboa-text outline-none focus:border-2 focus:border-mboa-primary"
          >
            {villes.length === 0 && <option value="">Chargement…</option>}
            {villes.map((v) => (
              <option key={v.id} value={v.nom}>
                {v.nom}
              </option>
            ))}
          </select>
          <p className="text-[11px] text-mboa-text-muted">
            Tes annonces apparaîtront par défaut dans cette ville.
          </p>
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
              Créer mon compte et envoyer la demande
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
    </div>
  );
}
