"use client";

import { useState, type FormEvent } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { parseAuthError } from "@/lib/utils/auth-errors";
import { validateEmail, validateTelephone, validateMotDePasse } from "@/lib/utils/validators";
import { AuthHeader } from "@/components/auth/auth-header";
import { TextField, FieldLabel } from "@/components/ui/text-field";
import { EmailIcon, PhoneIcon, LockIcon, EyeIcon, EyeOffIcon, CheckIcon } from "@/components/ui/icons";

const STEPS = [
  { label: "Profil", active: true },
  { label: "Accès", active: false },
  { label: "Terminé", active: false },
];

// Miroir exact de register_etudiant_screen.dart : header dégradé + indicateur
// d'étapes, nom/prénom côte à côte (min-w-0 sur les inputs pour éviter le
// débordement horizontal sur petits écrans), champs à icônes, règle de mot
// de passe alignée sur Validators.motDePasse (6 caractères minimum).
export default function RegisterEtudiantPage() {
  const router = useRouter();
  const [nom, setNom] = useState("");
  const [prenom, setPrenom] = useState("");
  const [email, setEmail] = useState("");
  const [telephone, setTelephone] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [acceptTerms, setAcceptTerms] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);

    const emailError = validateEmail(email);
    const telError = validateTelephone(telephone, false);
    const passError = validateMotDePasse(password);
    if (emailError) return setError(emailError);
    if (telError) return setError(telError);
    if (passError) return setError(passError);
    if (password !== confirmPassword) {
      setError("Les mots de passe ne correspondent pas");
      return;
    }
    if (!acceptTerms) {
      setError("Veuillez accepter les conditions d'utilisation");
      return;
    }

    setLoading(true);
    const supabase = createClient();
    const { error: authError } = await supabase.auth.signUp({
      email: email.trim(),
      password,
      options: {
        // Sans ça, le lien de confirmation par email retombe sur le "Site
        // URL" par défaut du projet Supabase — configuré pour le schéma
        // mobile (com.mboa.app://), donc inutilisable depuis un navigateur.
        // Miroir de resetPasswordForEmail (mot-de-passe-oublie/page.tsx),
        // qui fixe déjà explicitement son propre redirectTo.
        emailRedirectTo: `${window.location.origin}/login`,
        data: {
          nom: `${prenom.trim()} ${nom.trim()}`,
          telephone: telephone.trim() || null,
          role: "visiteur",
        },
      },
    });

    if (authError) {
      setError(parseAuthError(authError.message));
      setLoading(false);
      return;
    }

    setSuccess(true);
    setLoading(false);
    setTimeout(() => {
      router.push("/");
      router.refresh();
    }, 1500);
  }

  if (success) {
    return (
      <div className="mx-auto flex min-h-[70vh] max-w-md flex-col items-center justify-center px-4 text-center">
        <span className="text-4xl" aria-hidden>
          ✅
        </span>
        <h1 className="mt-4 text-xl font-extrabold text-mboa-text">Compte créé !</h1>
        <p className="mt-2 text-sm text-mboa-text-muted">
          Vérifie ton email pour confirmer ton compte. Redirection...
        </p>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-md pb-12">
      <AuthHeader
        title="Ton profil 🎓"
        subtitle="Quelques infos pour créer ton compte"
        steps={STEPS}
      />

      <form onSubmit={handleSubmit} className="flex flex-col gap-5 px-6 pt-6">
        {error && (
          <p className="rounded-mboa-md bg-mboa-danger/10 px-4 py-3 text-sm text-mboa-danger">{error}</p>
        )}

        <div className="flex gap-3">
          <label className="flex min-w-0 flex-1 flex-col gap-2">
            <FieldLabel>Nom</FieldLabel>
            <TextField
              type="text"
              required
              value={nom}
              onChange={(e) => setNom(e.target.value)}
              placeholder="Mbassi"
            />
          </label>
          <label className="flex min-w-0 flex-1 flex-col gap-2">
            <FieldLabel>Prénom</FieldLabel>
            <TextField
              type="text"
              required
              value={prenom}
              onChange={(e) => setPrenom(e.target.value)}
              placeholder="Jean-Paul"
            />
          </label>
        </div>

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
          <FieldLabel>WhatsApp (optionnel)</FieldLabel>
          <TextField
            type="tel"
            value={telephone}
            onChange={(e) => setTelephone(e.target.value)}
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
            type={showConfirm ? "text" : "password"}
            required
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            placeholder="••••••••"
            icon={<LockIcon />}
            suffix={
              <button
                type="button"
                onClick={() => setShowConfirm((v) => !v)}
                aria-label={showConfirm ? "Masquer le mot de passe" : "Afficher le mot de passe"}
                className="shrink-0 text-mboa-text-muted"
              >
                {showConfirm ? <EyeOffIcon /> : <EyeIcon />}
              </button>
            }
          />
        </label>

        <label className="flex items-start gap-2.5 text-xs leading-relaxed text-mboa-text-muted">
          <span className="relative mt-0.5 flex h-[22px] w-[22px] shrink-0 items-center justify-center">
            <input
              type="checkbox"
              checked={acceptTerms}
              onChange={(e) => setAcceptTerms(e.target.checked)}
              className="peer absolute inset-0 h-[22px] w-[22px] cursor-pointer appearance-none rounded border-[1.5px] border-mboa-border checked:border-mboa-primary checked:bg-mboa-primary"
            />
            <span className="pointer-events-none hidden text-white peer-checked:block">
              <CheckIcon />
            </span>
          </span>
          <span>
            J&apos;accepte les{" "}
            <span className="font-semibold text-mboa-primary">conditions d&apos;utilisation</span> et
            la <span className="font-semibold text-mboa-primary">politique de confidentialité</span>{" "}
            de Mboa.
          </span>
        </label>

        <button
          type="submit"
          disabled={loading}
          className="mt-2 flex h-[52px] items-center justify-center rounded-mboa-lg bg-mboa-primary text-sm font-bold text-white disabled:opacity-60"
        >
          {loading ? (
            <span className="h-5 w-5 animate-spin rounded-full border-2 border-white border-t-transparent" />
          ) : (
            "Créer mon compte"
          )}
        </button>

        <p className="mt-1 text-center text-sm">
          <span className="text-mboa-text-muted">Déjà un compte ? </span>
          <Link href="/login" className="font-bold text-mboa-primary">
            Se connecter
          </Link>
        </p>
      </form>
    </div>
  );
}
