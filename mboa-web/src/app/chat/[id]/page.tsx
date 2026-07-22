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
  const user = await getCurrentUser();
  if (!user) redirect("/login");

  const { id } = await params;
  const conversation = await getConversationDetail(id, user.id);
  if (!conversation) notFound();

  const messages = await getMessages(id);

  return <ConversationView conversation={conversation} initialMessages={messages} currentUserId={user.id} />;
}
