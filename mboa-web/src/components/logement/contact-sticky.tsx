"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

// Miroir de la barre d'actions fixe en bas de logement_detail_screen.dart /
// article_detail_screen.dart (_appelerProprietaire + _ouvrirChat).
export function ContactSticky({
  destinataireId,
  annonceId,
  annonceType,
  isLoggedIn,
}: {
  destinataireId: string;
  annonceId: string;
  annonceType: "logement" | "article";
  isLoggedIn: boolean;
}) {
  const router = useRouter();
  const [message, setMessage] = useState<string | null>(null);
  const [sending, setSending] = useState(false);

  async function appeler() {
    const supabase = createClient();
    const { data } = await supabase
      .from("users")
      .select("telephone")
      .eq("id", destinataireId)
      .single();

    const tel = data?.telephone as string | undefined;
    if (!tel) {
      setMessage("Numéro non renseigné");
      return;
    }
    window.location.assign(`tel:${tel}`);
  }

  async function envoyerMessage() {
    if (!isLoggedIn) {
      window.location.assign("/login");
      return;
    }
    setSending(true);
    const supabase = createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user || user.id === destinataireId) {
      setSending(false);
      return;
    }

    const { data: existing } = await supabase
      .from("conversations")
      .select("id")
      .contains("participants", [user.id, destinataireId])
      .eq("annonce_id", annonceId)
      .maybeSingle();

    let conversationId = existing?.id as string | undefined;
    if (!conversationId) {
      const { data: created } = await supabase
        .from("conversations")
        .insert({
          participants: [user.id, destinataireId],
          annonce_id: annonceId,
          annonce_type: annonceType,
          non_lu: { [user.id]: 0, [destinataireId]: 0 },
        })
        .select("id")
        .single();
      conversationId = created?.id;
    }

    setSending(false);
    if (conversationId) {
      router.push(`/chat/${conversationId}`);
    } else {
      setMessage("Impossible de démarrer la conversation. Réessaie.");
    }
  }

  return (
    <div className="sticky bottom-0 z-10 border-t border-mboa-border bg-mboa-card px-5 py-3 shadow-[0_-4px_20px_rgba(0,0,0,0.08)]">
      <div className="mx-auto flex max-w-3xl gap-3">
        <button
          onClick={appeler}
          className="flex-1 rounded-mboa-lg border border-mboa-primary py-3 text-sm font-bold text-mboa-primary"
        >
          📞 Appeler
        </button>
        {isLoggedIn ? (
          <button
            onClick={envoyerMessage}
            disabled={sending}
            className="flex-[2] rounded-mboa-lg bg-mboa-primary py-3 text-sm font-bold text-white disabled:opacity-60"
          >
            {sending ? "..." : "💬 Envoyer un message"}
          </button>
        ) : (
          <Link
            href="/login"
            className="flex-[2] rounded-mboa-lg bg-mboa-primary py-3 text-center text-sm font-bold text-white"
          >
            💬 Envoyer un message
          </Link>
        )}
      </div>
      {message && (
        <p className="mx-auto mt-2 max-w-3xl text-center text-xs text-mboa-text-muted">
          {message}
        </p>
      )}
    </div>
  );
}
