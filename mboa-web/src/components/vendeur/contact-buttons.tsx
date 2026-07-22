"use client";

import Link from "next/link";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

// Miroir de _appeler / _envoyerMessage dans profil_vendeur_screen.dart.
export function ContactButtons({
  vendeurId,
  isLoggedIn,
  isSelf,
}: {
  vendeurId: string;
  isLoggedIn: boolean;
  isSelf: boolean;
}) {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [sending, setSending] = useState(false);

  if (isSelf) return null;

  async function handleAppeler() {
    const supabase = createClient();
    const { data } = await supabase
      .from("users")
      .select("telephone")
      .eq("id", vendeurId)
      .single();

    const tel = data?.telephone as string | undefined;
    if (!tel) {
      setError("Numéro non renseigné par ce contributeur");
      return;
    }
    window.location.assign(`tel:${tel}`);
  }

  async function handleMessage() {
    setError(null);
    setSending(true);
    const supabase = createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user || user.id === vendeurId) {
      setSending(false);
      return;
    }

    const { data: existing } = await supabase
      .from("conversations")
      .select("id")
      .contains("participants", [user.id, vendeurId])
      .maybeSingle();

    let conversationId = existing?.id as string | undefined;
    if (!conversationId) {
      const { data: created } = await supabase
        .from("conversations")
        .insert({
          participants: [user.id, vendeurId],
          non_lu: { [user.id]: 0, [vendeurId]: 0 },
        })
        .select("id")
        .single();
      conversationId = created?.id;
    }

    setSending(false);
    if (conversationId) {
      router.push(`/chat/${conversationId}`);
    } else {
      setError("Impossible de démarrer la conversation. Réessaie.");
    }
  }

  return (
    <div>
      {error && (
        <p className="mb-2 rounded-mboa-md bg-white/15 px-3 py-2 text-xs text-white">
          {error}
        </p>
      )}
      <div className="flex gap-3">
        <button
          onClick={handleAppeler}
          className="flex-1 rounded-mboa-lg border border-white/40 py-2.5 text-sm font-bold text-white"
        >
          📞 Appeler
        </button>
        {isLoggedIn ? (
          <button
            onClick={handleMessage}
            disabled={sending}
            className="flex-1 rounded-mboa-lg bg-white py-2.5 text-sm font-bold text-mboa-primary disabled:opacity-60"
          >
            {sending ? "..." : "💬 Message"}
          </button>
        ) : (
          <Link
            href="/login"
            className="flex-1 rounded-mboa-lg bg-white py-2.5 text-center text-sm font-bold text-mboa-primary"
          >
            💬 Message
          </Link>
        )}
      </div>
    </div>
  );
}
