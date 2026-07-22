import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";

export const metadata: Metadata = {
  title: "Messages",
};

// Miroir de chat_screen.dart : la messagerie temps réel n'existe pas encore
// sur le web (nécessite l'infrastructure Realtime complète). En attendant,
// on explique clairement où retrouver la fonctionnalité, comme pour
// ContactSticky/ContactButtons dans les pages de détail.
export default async function ChatPage() {
  const user = await getCurrentUser();
  if (!user) redirect("/login");

  return (
    <div className="mx-auto flex min-h-[60vh] max-w-md flex-col items-center justify-center px-4 text-center">
      <span className="text-4xl" aria-hidden>
        💬
      </span>
      <h1 className="mt-4 text-xl font-extrabold text-mboa-text">Messagerie</h1>
      <p className="mt-2 text-sm leading-relaxed text-mboa-text-muted">
        La messagerie en temps réel arrive bientôt sur le web. En attendant, utilise l&apos;app
        mobile Mboa pour discuter avec les propriétaires et vendeurs.
      </p>
    </div>
  );
}
