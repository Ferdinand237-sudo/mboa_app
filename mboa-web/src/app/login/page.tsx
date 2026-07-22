"use client";

import { useState, useSyncExternalStore, type FormEvent } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { parseAuthError } from "@/lib/utils/auth-errors";
import { AuthHeader } from "@/components/auth/auth-header";
import { TextField, FieldLabel } from "@/components/ui/text-field";
import { EmailIcon, LockIcon, EyeIcon, EyeOffIcon, CheckIcon } from "@/components/ui/icons";
import { GoogleButton } from "@/components/auth/google-button";
import { OrDivider } from "@/components/auth/or-divider";

const REMEMBER_EMAIL_KEY = "mboa_remembered_email";

function subscribeStorage(callback: () => void) {
  window.addEventListener("storage", callback);
  return () => window.removeEventListener("storage", callback);
}
function getRememberedEmail() {
  return window.localStorage.getItem(REMEMBER_EMAIL_KEY) ?? "";
}
function getRememberedEmailServer() {
  return "";
}

// Miroir de login_screen.dart : header dégradé, champs à icônes, "se souvenir
// de moi" (localStorage web, équivalent du secure storage mobile), mot de
// passe oublié, connexion Google, lien inscription.
export default function LoginPage() {
  const router = useRouter();
  // useSyncExternalStore lit localStorage sans setState-in-effect : React
  // resynchronise automatiquement après l'hydratation, sans avertissement.
  const rememberedEmail = useSyncExternalStore(
    subscribeStorage,
    getRememberedEmail,
    getRememberedEmailServer,
  );
  const [emailOverride, setEmailOverride] = useState<string | null>(null);
  const [rememberMeOverride, setRememberMeOverride] = useState<boolean | null>(null);
  const email = emailOverride ?? rememberedEmail;
  const rememberMe = rememberMeOverride ?? rememberedEmail !== "";
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);

    const supabase = createClient();
    const { error: authError } = await supabase.auth.signInWithPassword({
      email: email.trim(),
      password,
    });

    if (authError) {
      setError(parseAuthError(authError.message));
      setLoading(false);
      return;
    }

    if (rememberMe) {
      window.localStorage.setItem(REMEMBER_EMAIL_KEY, email.trim());
    } else {
      window.localStorage.removeItem(REMEMBER_EMAIL_KEY);
    }

    router.push("/");
    router.refresh();
  }

  return (
    <div className="mx-auto max-w-md pb-12">
      <AuthHeader showLogo title="Bon retour ! 👋" subtitle="Connecte-toi pour accéder à ton compte" />

      <form onSubmit={handleSubmit} className="flex flex-col gap-5 px-6 pt-6">
        {error && (
          <p className="rounded-mboa-md bg-mboa-danger/10 px-4 py-3 text-sm text-mboa-danger">{error}</p>
        )}

        <label className="flex flex-col gap-2">
          <FieldLabel>Email</FieldLabel>
          <TextField
            type="email"
            required
            value={email}
            onChange={(e) => setEmailOverride(e.target.value)}
            placeholder="ton@email.com"
            icon={<EmailIcon />}
          />
        </label>

        <label className="flex flex-col gap-2">
          <FieldLabel>Mot de passe</FieldLabel>
          <TextField
            type={showPassword ? "text" : "password"}
            required
            minLength={6}
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

        <div className="flex items-center justify-between">
          <label className="flex items-center gap-2 text-[13px] text-mboa-text">
            <span className="relative flex h-5 w-5 shrink-0 items-center justify-center">
              <input
                type="checkbox"
                checked={rememberMe}
                onChange={(e) => setRememberMeOverride(e.target.checked)}
                className="peer absolute inset-0 h-5 w-5 cursor-pointer appearance-none rounded border-[1.5px] border-mboa-border checked:border-mboa-primary checked:bg-mboa-primary"
              />
              <span className="pointer-events-none hidden text-white peer-checked:block">
                <CheckIcon />
              </span>
            </span>
            Se souvenir de moi
          </label>
          <Link href="/mot-de-passe-oublie" className="text-xs font-semibold text-mboa-primary">
            Mot de passe oublié ?
          </Link>
        </div>

        <button
          type="submit"
          disabled={loading}
          className="mt-2 flex h-[52px] items-center justify-center rounded-mboa-lg bg-mboa-primary text-sm font-bold text-white disabled:opacity-60"
        >
          {loading ? (
            <span className="h-5 w-5 animate-spin rounded-full border-2 border-white border-t-transparent" />
          ) : (
            "Se connecter"
          )}
        </button>

        <OrDivider />

        <GoogleButton />

        <p className="mt-4 text-center text-sm">
          <span className="text-mboa-text-muted">Pas encore de compte ? </span>
          <Link href="/register" className="font-bold text-mboa-primary">
            S&apos;inscrire
          </Link>
        </p>
      </form>
    </div>
  );
}
