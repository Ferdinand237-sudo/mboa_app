"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

// Miroir de _connexionGoogle (login_screen.dart / register_screen.dart).
// Sur mobile la redirection utilise un schéma custom (com.mboa.app://) ;
// sur web on redirige vers l'origine courante, gérée par le callback OAuth
// standard de Supabase (échange de session côté client via detectSessionInUrl).
export function GoogleButton() {
  const [loading, setLoading] = useState(false);

  async function connexionGoogle() {
    setLoading(true);
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithOAuth({
      provider: "google",
      options: { redirectTo: `${window.location.origin}/` },
    });
    if (error) setLoading(false);
  }

  return (
    <button
      onClick={connexionGoogle}
      disabled={loading}
      className="flex h-[52px] w-full items-center justify-center gap-2.5 rounded-mboa-lg border-[1.5px] border-mboa-border bg-mboa-card text-sm font-bold text-mboa-primary disabled:opacity-60"
    >
      {loading ? (
        <span className="h-5 w-5 animate-spin rounded-full border-2 border-mboa-primary border-t-transparent" />
      ) : (
        <>
          <svg viewBox="0 0 24 24" className="h-5 w-5">
            <path
              fill="#4285F4"
              d="M23.5 12.3c0-.9-.1-1.6-.2-2.3H12v4.4h6.5c-.3 1.5-1.1 2.7-2.4 3.6v3h3.9c2.3-2.1 3.5-5.2 3.5-8.7Z"
            />
            <path
              fill="#34A853"
              d="M12 24c3.2 0 6-1.1 7.9-2.9l-3.9-3c-1.1.7-2.4 1.2-4 1.2-3.1 0-5.7-2.1-6.6-4.9H1.4v3.1C3.3 21.3 7.3 24 12 24Z"
            />
            <path fill="#FBBC05" d="M5.4 14.4c-.2-.7-.4-1.5-.4-2.4s.1-1.6.4-2.4V6.5H1.4A12 12 0 0 0 0 12c0 1.9.5 3.8 1.4 5.5l4-3.1Z" />
            <path
              fill="#EA4335"
              d="M12 4.8c1.7 0 3.3.6 4.5 1.7l3.4-3.4C17.9 1.2 15.1 0 12 0 7.3 0 3.3 2.7 1.4 6.5l4 3.1C6.3 6.9 8.9 4.8 12 4.8Z"
            />
          </svg>
          <span>Continuer avec Google</span>
        </>
      )}
    </button>
  );
}
