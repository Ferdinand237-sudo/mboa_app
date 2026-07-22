import type { Metadata } from "next";
import { getCurrentUser } from "@/lib/data/auth";
import { getConversations } from "@/lib/data/chat";
import { ChatList } from "@/components/chat/chat-list";

export const metadata: Metadata = {
  title: "Messages",
};

// Miroir de ChatScreen (chat_screen.dart).
export default async function ChatPage() {
  const user = await getCurrentUser();

  if (!user) {
    return (
      <div className="mx-auto flex min-h-[70vh] max-w-md flex-col items-center justify-center px-8 text-center">
        <span className="text-6xl" aria-hidden>
          💬
        </span>
        <h1 className="mt-4 text-lg font-bold text-mboa-text">Vos conversations</h1>
        <p className="mt-2 text-sm leading-relaxed text-mboa-text-muted">
          Connectez-vous pour envoyer des messages aux vendeurs et propriétaires
        </p>
      </div>
    );
  }

  const conversations = await getConversations(user.id);

  return <ChatList conversations={conversations} />;
}
