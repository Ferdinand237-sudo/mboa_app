"use client";

import { useState, type FormEvent } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { parseAuthError } from "@/lib/utils/auth-errors";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);

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

    router.push("/");
    router.refresh();
  }

  return (
    <div className="mx-auto flex min-h-[70vh] max-w-md flex-col justify-center px-4 py-12 sm:px-6">
      <h1 className="text-2xl font-extrabold text-mboa-text">Connexion</h1>
      <p className="mt-1 text-sm text-mboa-text-muted">
        Content de te revoir sur Mboa.
      </p>

      <form onSubmit={handleSubmit} className="mt-8 flex flex-col gap-5">
        {error && (
          <p className="rounded-mboa-md bg-mboa-danger/10 px-4 py-3 text-sm text-mboa-danger">
            {error}
          </p>
        )}

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
            Mot de passe
          </span>
          <input
            type="password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            className="rounded-mboa-md border border-mboa-border bg-mboa-background px-4 py-3 text-sm outline-none focus:border-mboa-primary"
          />
        </label>

        <button
          type="submit"
          disabled={loading}
          className="rounded-mboa-lg bg-mboa-primary py-3.5 text-sm font-bold text-white disabled:opacity-60"
        >
          {loading ? "Connexion..." : "Se connecter"}
        </button>
      </form>

      <p className="mt-6 text-center text-sm text-mboa-text-muted">
        Pas encore de compte ?{" "}
        <Link href="/register" className="font-bold text-mboa-primary">
          S&apos;inscrire
        </Link>
      </p>
    </div>
  );
}
