"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { validateMotDePasse } from "@/lib/utils/validators";
import { TextField } from "@/components/ui/text-field";
import { LockIcon, EyeIcon, EyeOffIcon } from "@/components/ui/icons";

// Miroir de reset_password_screen.dart : atteint via le lien email de
// resetPasswordForEmail (Supabase établit la session depuis le hash d'URL).
export default function ReinitialiserMotDePassePage() {
  const router = useRouter();
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    const passError = validateMotDePasse(password);
    if (passError) {
      setError(passError);
      return;
    }
    if (password !== confirm) {
      setError("Les mots de passe ne correspondent pas");
      return;
    }
    setError(null);
    setLoading(true);
    const supabase = createClient();
    const { error: updateError } = await supabase.auth.updateUser({ password });
    setLoading(false);
    if (updateError) {
      setError("Impossible de mettre à jour le mot de passe");
      return;
    }
    router.push("/");
    router.refresh();
  }

  return (
    <div className="mx-auto max-w-md px-6 py-10">
      <span className="text-5xl" aria-hidden>
        🔒
      </span>
      <h1 className="mt-5 text-2xl font-extrabold text-mboa-text">Nouveau mot de passe</h1>
      <p className="mt-2 text-[13px] leading-relaxed text-mboa-text-muted">
        Choisis un nouveau mot de passe pour ton compte Mboa.
      </p>

      <form onSubmit={handleSubmit} className="mt-7 flex flex-col gap-4">
        {error && (
          <p className="rounded-mboa-md bg-mboa-danger/10 px-4 py-3 text-sm text-mboa-danger">{error}</p>
        )}

        <TextField
          type={showPassword ? "text" : "password"}
          required
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          placeholder="Nouveau mot de passe"
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

        <TextField
          type={showPassword ? "text" : "password"}
          required
          value={confirm}
          onChange={(e) => setConfirm(e.target.value)}
          placeholder="Confirmer le mot de passe"
          icon={<LockIcon />}
        />

        <button
          type="submit"
          disabled={loading}
          className="mt-3 flex h-[52px] items-center justify-center rounded-mboa-lg bg-mboa-primary text-sm font-bold text-white disabled:opacity-60"
        >
          {loading ? (
            <span className="h-5 w-5 animate-spin rounded-full border-2 border-white border-t-transparent" />
          ) : (
            "Valider"
          )}
        </button>
      </form>
    </div>
  );
}
