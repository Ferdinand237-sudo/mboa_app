import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";
import { getConversationDetail, getMessages } from "@/lib/data/chat";
import { ConversationView } from "@/components/chat/conversation-view";

export const metadata: Metadata = {
  title: "Conversation",
};

// Miroir de ConversationScreen (chat_screen.dart) — publique dans l'app
// (utilisée aussi depuis logement_detail/article_detail), mais nécessite
// tout de même une session pour identifier l'utilisateur courant.
export default async function ConversationPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  // getMessages ne dépend pas de l'utilisateur : on la lance en parallèle
  // de getCurrentUser au lieu d'enchaîner les allers-retours Supabase un
  // par un (c'est cette latence en série qui donnait l'impression que le
  // clic sur une conversation ne répondait pas).
  const [user, messages] = await Promise.all([getCurrentUser(), getMessages(id)]);
  if (!user) redirect("/login");

  const conversation = await getConversationDetail(id, user.id);
  if (!conversation) notFound();

  return <ConversationView conversation={conversation} initialMessages={messages} currentUserId={user.id} />;
}
