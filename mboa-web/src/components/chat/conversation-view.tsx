"use client";

import { useEffect, useRef, useState, type FormEvent } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import { BackButton } from "@/components/ui/back-button";
import { Dialog } from "@/components/ui/dialog";
import { Photo } from "@/components/ui/photo";
import { StarIcon, SendIcon, ChevronRightIcon } from "@/components/ui/icons";
import { initiales } from "@/lib/utils/format";
import type { ConversationDetail, MessageRow } from "@/lib/data/chat";

function formatHeure(dateStr: string): string {
  const d = new Date(dateStr);
  return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
}

function memeJour(a: string, b: string): boolean {
  const da = new Date(a);
  const db = new Date(b);
  return da.getFullYear() === db.getFullYear() && da.getMonth() === db.getMonth() && da.getDate() === db.getDate();
}

function formatDateSeparateur(dateStr: string): string {
  const d = new Date(dateStr);
  const now = new Date();
  const aujourdhui = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const hier = new Date(aujourdhui);
  hier.setDate(hier.getDate() - 1);
  const jour = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  if (jour.getTime() === aujourdhui.getTime()) return "Aujourd'hui";
  if (jour.getTime() === hier.getTime()) return "Hier";
  const mois = ["janv.", "févr.", "mars", "avr.", "mai", "juin", "juil.", "août", "sept.", "oct.", "nov.", "déc."];
  return `${d.getDate()} ${mois[d.getMonth()]} ${d.getFullYear()}`;
}

// Miroir de ConversationScreen (chat_screen.dart) : messages temps réel via
// un canal dédié conv_<id>, fermé au démontage (même principe que le
// commentaire CLAUDE.md sur le premier usage de Realtime dans le projet).
export function ConversationView({
  conversation,
  initialMessages,
  currentUserId,
}: {
  conversation: ConversationDetail;
  initialMessages: MessageRow[];
  currentUserId: string;
}) {
  const [messages, setMessages] = useState(initialMessages);
  const [texte, setTexte] = useState("");
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const supabase = createClient();

    async function marquerLus() {
      await supabase
        .from("messages")
        .update({ lu: true })
        .eq("conversation_id", conversation.id)
        .neq("expediteur_id", currentUserId);
    }
    marquerLus();

    const channel = supabase
      .channel(`conv_${conversation.id}`)
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "messages",
          filter: `conversation_id=eq.${conversation.id}`,
        },
        (payload) => {
          const n = payload.new as {
            id: string;
            conversation_id: string;
            expediteur_id: string;
            texte: string;
            lu: boolean;
            date_envoi: string;
          };
          setMessages((prev) => [
            ...prev,
            {
              id: n.id,
              conversationId: n.conversation_id,
              expediteurId: n.expediteur_id,
              texte: n.texte,
              lu: n.lu === true,
              dateEnvoi: n.date_envoi,
            },
          ]);
          marquerLus();
        },
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [conversation.id, currentUserId]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages.length]);

  async function envoyer(e: FormEvent) {
    e.preventDefault();
    const contenu = texte.trim();
    if (!contenu) return;
    setTexte("");
    const supabase = createClient();
    await supabase.from("messages").insert({
      conversation_id: conversation.id,
      expediteur_id: currentUserId,
      texte: contenu,
    });
    await supabase
      .from("conversations")
      .update({ dernier_message: contenu, dernier_message_date: new Date().toISOString() })
      .eq("id", conversation.id);
  }

  return (
    <div>
      <div className="bg-white px-4 py-3">
        <div className="mx-auto flex max-w-2xl items-center gap-3">
          <BackButton />
          <div className="relative h-9 w-9 shrink-0 overflow-hidden rounded-full bg-mboa-primary">
            {conversation.autrePhotoUrl ? (
              <Photo src={conversation.autrePhotoUrl} alt={conversation.autreNom} className="rounded-full" />
            ) : (
              <span className="flex h-full w-full items-center justify-center text-xs font-bold text-white">
                {initiales(conversation.autreNom)}
              </span>
            )}
          </div>
          <div className="min-w-0 flex-1">
            <p className="flex items-center gap-1 truncate text-sm font-bold text-mboa-text">
              {conversation.autreNom}
              {conversation.autreVerified && <span className="text-mboa-verified">✅</span>}
            </p>
            <p className="text-[11px] font-medium text-mboa-verified">● En ligne</p>
          </div>
          <AvisButton autreId={conversation.autreId} autreNom={conversation.autreNom} annonceId={conversation.annonceId} />
        </div>

        {conversation.annonceId && (
          <Link
            href={conversation.annonceType === "logement" ? `/logements/${conversation.annonceId}` : `/marketplace/${conversation.annonceId}`}
            className="mx-auto mt-2.5 flex max-w-2xl items-center gap-1 rounded-lg bg-mboa-primary/8 px-3 py-1.5 text-xs font-semibold text-mboa-primary"
          >
            <span className="truncate">{conversation.sujet}</span>
            <ChevronRightIcon className="h-3.5 w-3.5 shrink-0" />
          </Link>
        )}
      </div>

      <div className="mx-auto min-h-[55vh] max-w-2xl px-4 py-4">
        {messages.length === 0 ? (
          <p className="py-16 text-center text-sm text-mboa-text-muted">Démarrez la conversation 👋</p>
        ) : (
          messages.map((msg, i) => {
            const showSeparateur = i === 0 || !memeJour(messages[i - 1].dateEnvoi, msg.dateEnvoi);
            const isMoi = msg.expediteurId === currentUserId;
            return (
              <div key={msg.id}>
                {showSeparateur && (
                  <div className="my-3.5 flex justify-center">
                    <span className="rounded-full bg-mboa-text-muted/12 px-3 py-1 text-[11px] font-semibold text-mboa-text-muted">
                      {formatDateSeparateur(msg.dateEnvoi)}
                    </span>
                  </div>
                )}
                <div className={`mb-3 flex items-end gap-2 ${isMoi ? "justify-end" : "justify-start"}`}>
                  {!isMoi && (
                    <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-mboa-primary text-[10px] font-bold text-white">
                      {initiales(conversation.autreNom)}
                    </span>
                  )}
                  <div
                    className={`max-w-[75%] rounded-2xl px-3.5 py-2.5 shadow-sm ${
                      isMoi ? "rounded-br-md bg-mboa-primary text-white" : "rounded-bl-md bg-white text-mboa-text"
                    }`}
                  >
                    <p className="text-[13px] leading-relaxed">{msg.texte}</p>
                    <div className="mt-1 flex items-center justify-end gap-1">
                      <span className={`text-[10px] ${isMoi ? "text-white/70" : "text-mboa-text-muted"}`}>
                        {formatHeure(msg.dateEnvoi)}
                      </span>
                      {isMoi && (
                        <span className={`text-[11px] ${msg.lu ? "text-white" : "text-white/60"}`}>
                          {msg.lu ? "✓✓" : "✓"}
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            );
          })
        )}
        <div ref={bottomRef} />
      </div>

      <form
        onSubmit={envoyer}
        className="sticky bottom-0 flex items-center gap-2.5 border-t border-mboa-border bg-white px-4 py-3"
      >
        <div className="mx-auto flex w-full max-w-2xl items-center gap-2.5">
          <input
            value={texte}
            onChange={(e) => setTexte(e.target.value)}
            placeholder="Écrire un message..."
            className="min-w-0 flex-1 rounded-full border border-mboa-border bg-mboa-background px-4 py-3 text-sm text-mboa-text outline-none placeholder:text-mboa-text-muted"
          />
          <button
            type="submit"
            aria-label="Envoyer"
            className="flex h-[46px] w-[46px] shrink-0 items-center justify-center rounded-full bg-mboa-primary text-white"
          >
            <SendIcon className="h-5 w-5" />
          </button>
        </div>
      </form>
    </div>
  );
}

function AvisButton({
  autreId,
  autreNom,
  annonceId,
}: {
  autreId: string;
  autreNom: string;
  annonceId: string | null;
}) {
  const [open, setOpen] = useState(false);
  const [note, setNote] = useState(5);
  const [commentaire, setCommentaire] = useState("");
  const [sending, setSending] = useState(false);
  const [feedback, setFeedback] = useState<string | null>(null);

  async function envoyerAvis() {
    setSending(true);
    const supabase = createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      setSending(false);
      return;
    }
    const necessiteModeration = annonceId != null;
    const { error } = await supabase.from("avis").insert({
      auteur_id: user.id,
      cible_id: autreId,
      annonce_id: annonceId,
      note,
      commentaire: commentaire.trim(),
      valide: !necessiteModeration,
    });
    setSending(false);
    if (!error) {
      setFeedback(
        necessiteModeration
          ? "Merci ! Votre avis sera visible dès validation par le propriétaire (ou automatiquement sous 72h)."
          : "Merci pour votre avis !",
      );
      setTimeout(() => {
        setOpen(false);
        setFeedback(null);
        setNote(5);
        setCommentaire("");
      }, 1400);
    } else {
      setFeedback("Erreur lors de l'envoi de l'avis");
    }
  }

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        aria-label="Laisser un avis"
        className="shrink-0 text-mboa-boost"
      >
        <StarIcon className="h-6 w-6" />
      </button>
      <Dialog open={open} onClose={() => setOpen(false)}>
        <h2 className="text-base font-extrabold text-mboa-text">⭐ Laisser un avis</h2>
        <p className="mt-1.5 text-sm text-mboa-text-muted">Votre expérience avec {autreNom}</p>
        <div className="mt-3 flex justify-center gap-1">
          {[1, 2, 3, 4, 5].map((v) => (
            <button key={v} type="button" onClick={() => setNote(v)} aria-label={`${v} étoiles`}>
              <StarIcon className={`h-8 w-8 ${v <= note ? "text-mboa-boost" : "text-mboa-border"}`} />
            </button>
          ))}
        </div>
        <textarea
          value={commentaire}
          onChange={(e) => setCommentaire(e.target.value)}
          rows={3}
          placeholder="Votre commentaire (optionnel)"
          className="mt-3 w-full rounded-mboa-md border border-mboa-border bg-mboa-background px-3.5 py-3 text-sm text-mboa-text outline-none focus:border-2 focus:border-mboa-primary"
        />
        {feedback && <p className="mt-2 text-xs font-semibold text-mboa-primary">{feedback}</p>}
        <div className="mt-4 flex justify-end gap-3">
          <button
            type="button"
            onClick={() => setOpen(false)}
            className="rounded-mboa-md px-4 py-2 text-sm font-semibold text-mboa-text-muted"
          >
            Annuler
          </button>
          <button
            type="button"
            onClick={envoyerAvis}
            disabled={sending}
            className="rounded-mboa-md bg-mboa-primary px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
          >
            Envoyer
          </button>
        </div>
      </Dialog>
    </>
  );
}
