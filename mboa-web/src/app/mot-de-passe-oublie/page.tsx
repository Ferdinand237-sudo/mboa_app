"use client";

import { useState, type FormEvent } from "react";
import { validateEmail } from "@/lib/utils/validators";
import { createClient } from "@/lib/supabase/client";
import { BackButton } from "@/components/ui/back-button";
import { TextField } from "@/components/ui/text-field";
import { EmailIcon } from "@/components/ui/icons";

// Miroir de forgot_password_screen.dart : simple, pas de header dégradé,
// juste un bouton retour et deux états (formulaire / confirmation envoyée).
export default function MotDePasseOubliePage() {
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [sent, setSent] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    const emailError = validateEmail(email);
    if (emailError) {
      setError(emailError);
      return;
    }
    setError(null);
    setLoading(true);
    const supabase = createClient();
    const { error: resetError } = await supabase.auth.resetPasswordForEmail(email.trim(), {
      redirectTo: `${window.location.origin}/reinitialiser-mot-de-passe`,
    });
    setLoading(false);
    if (resetError) {
      setError("Une erreur est survenue. Réessayez.");
      return;
    }
    setSent(true);
  }

  return (
    <div className="mx-auto max-w-md px-6 py-6">
      <BackButton />

      {sent ? (
        <div className="mt-5">
          <span className="text-5xl" aria-hidden>
            📩
          </span>
          <h1 className="mt-5 text-2xl font-extrabold text-mboa-text">Email envoyé !</h1>
          <p className="mt-2 text-[13px] leading-relaxed text-mboa-text-muted">
            Un lien de réinitialisation a été envoyé à {email.trim()}. Ouvre-le pour choisir un
            nouveau mot de passe.
          </p>
          <button
            onClick={() => window.history.back()}
            className="mt-7 flex h-[52px] w-full items-center justify-center rounded-mboa-lg border-[1.5px] border-mboa-primary text-sm font-bold text-mboa-primary"
          >
            Retour à la connexion
          </button>
        </div>
      ) : (
        <form onSubmit={handleSubmit} className="mt-5 flex flex-col gap-6">
          <div>
            <span className="text-5xl" aria-hidden>
              🔑
            </span>
            <h1 className="mt-5 text-2xl font-extrabold text-mboa-text">Mot de passe oublié ?</h1>
            <p className="mt-2 text-[13px] leading-relaxed text-mboa-text-muted">
              Entre ton email et nous t&apos;enverrons un lien pour réinitialiser ton mot de passe.
            </p>
          </div>

          {error && (
            <p className="rounded-mboa-md bg-mboa-danger/10 px-4 py-3 text-sm text-mboa-danger">{error}</p>
          )}

          <TextField
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="ton@email.com"
            icon={<EmailIcon />}
          />

          <button
            type="submit"
            disabled={loading}
            className="flex h-[52px] items-center justify-center rounded-mboa-lg bg-mboa-primary text-sm font-bold text-white disabled:opacity-60"
          >
            {loading ? (
              <span className="h-5 w-5 animate-spin rounded-full border-2 border-white border-t-transparent" />
            ) : (
              "Envoyer le lien"
            )}
          </button>
        </form>
      )}
    </div>
  );
}
