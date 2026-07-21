"use client";

import { useState, type FormEvent } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { parseAuthError } from "@/lib/utils/auth-errors";

export default function RegisterPage() {
  const router = useRouter();
  const [nom, setNom] = useState("");
  const [prenom, setPrenom] = useState("");
  const [email, setEmail] = useState("");
  const [telephone, setTelephone] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [acceptTerms, setAcceptTerms] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);

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
        <h1 className="mt-4 text-xl font-extrabold text-mboa-text">
          Compte créé !
        </h1>
        <p className="mt-2 text-sm text-mboa-text-muted">
          Vérifie ton email pour confirmer ton compte. Redirection...
        </p>
      </div>
    );
  }

  return (
    <div className="mx-auto flex max-w-md flex-col px-4 py-12 sm:px-6">
      <h1 className="text-2xl font-extrabold text-mboa-text">
        Ton profil 🎓
      </h1>
      <p className="mt-1 text-sm text-mboa-text-muted">
        Quelques infos pour créer ton compte étudiant.
      </p>

      <form onSubmit={handleSubmit} className="mt-8 flex flex-col gap-5">
        {error && (
          <p className="rounded-mboa-md bg-mboa-danger/10 px-4 py-3 text-sm text-mboa-danger">
            {error}
          </p>
        )}

        <div className="flex gap-3">
          <label className="flex flex-1 flex-col gap-2">
            <span className="text-sm font-semibold text-mboa-text">Nom</span>
            <input
              type="text"
              required
              value={nom}
              onChange={(e) => setNom(e.target.value)}
              placeholder="Mbassi"
              className="rounded-mboa-md border border-mboa-border bg-mboa-background px-4 py-3 text-sm outline-none focus:border-mboa-primary"
            />
          </label>
          <label className="flex flex-1 flex-col gap-2">
            <span className="text-sm font-semibold text-mboa-text">
              Prénom
            </span>
            <input
              type="text"
              required
              value={prenom}
              onChange={(e) => setPrenom(e.target.value)}
              placeholder="Jean-Paul"
              className="rounded-mboa-md border border-mboa-border bg-mboa-background px-4 py-3 text-sm outline-none focus:border-mboa-primary"
            />
          </label>
        </div>

        <label className="flex flex-col gap-2">
          <span className="text-sm font-semibold text-mboa-text">Email</span>
          <input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="ton@email.com"
            className="rounded-mboa-md border border-mboa-border bg-mboa-background px-4 py-3 text-sm outline-none focus:border-mboa-primary"
          />
        </label>

        <label className="flex flex-col gap-2">
          <span className="text-sm font-semibold text-mboa-text">
            WhatsApp (optionnel)
          </span>
          <input
            type="tel"
            value={telephone}
            onChange={(e) => setTelephone(e.target.value)}
            placeholder="+237 6XX XXX XXX"
            className="rounded-mboa-md border border-mboa-border bg-mboa-background px-4 py-3 text-sm outline-none focus:border-mboa-primary"
          />
        </label>

        <label className="flex flex-col gap-2">
          <span className="text-sm font-semibold text-mboa-text">
            Mot de passe
          </span>
          <input
            type="password"
            required
            minLength={6}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            className="rounded-mboa-md border border-mboa-border bg-mboa-background px-4 py-3 text-sm outline-none focus:border-mboa-primary"
          />
        </label>

        <label className="flex flex-col gap-2">
          <span className="text-sm font-semibold text-mboa-text">
            Confirmer le mot de passe
          </span>
          <input
            type="password"
            required
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            placeholder="••••••••"
            className="rounded-mboa-md border border-mboa-border bg-mboa-background px-4 py-3 text-sm outline-none focus:border-mboa-primary"
          />
        </label>

        <label className="flex items-start gap-2.5 text-xs leading-relaxed text-mboa-text-muted">
          <input
            type="checkbox"
            checked={acceptTerms}
            onChange={(e) => setAcceptTerms(e.target.checked)}
            className="mt-0.5 h-4 w-4 shrink-0 accent-mboa-primary"
          />
          <span>
            J&apos;accepte les{" "}
            <span className="font-semibold text-mboa-primary">
              conditions d&apos;utilisation
            </span>{" "}
            et la{" "}
            <span className="font-semibold text-mboa-primary">
              politique de confidentialité
            </span>{" "}
            de Mboa.
          </span>
        </label>

        <button
          type="submit"
          disabled={loading}
          className="mt-2 rounded-mboa-lg bg-mboa-primary py-3.5 text-sm font-bold text-white disabled:opacity-60"
        >
          {loading ? "Création..." : "Créer mon compte"}
        </button>
      </form>

      <p className="mt-6 text-center text-sm text-mboa-text-muted">
        Déjà un compte ?{" "}
        <Link href="/login" className="font-bold text-mboa-primary">
          Se connecter
        </Link>
      </p>
    </div>
  );
}
