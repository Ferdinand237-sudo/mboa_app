import type { Metadata } from "next";
import Link from "next/link";
import { getCurrentUser } from "@/lib/data/auth";
import { getProfilStats } from "@/lib/data/profil-stats";
import { ProfilConnected } from "@/components/profil/profil-connected";

export const metadata: Metadata = {
  title: "Mon profil",
};

// Miroir de profil_screen.dart : deux vues selon l'état de connexion (pas de
// redirection forcée — un visiteur non inscrit voit un écran d'invitation).
export default async function ProfilPage() {
  const user = await getCurrentUser();

  if (!user) {
    return (
      <div className="mx-auto flex min-h-[70vh] max-w-md flex-col items-center justify-center px-8 text-center">
        <span className="flex h-[100px] w-[100px] items-center justify-center rounded-full bg-mboa-primary/10 text-5xl">
          👤
        </span>
        <h1 className="mt-6 text-[22px] font-extrabold text-mboa-text">Mon Profil</h1>
        <p className="mt-3 text-sm leading-relaxed text-mboa-text-muted">
          Veuillez créer un compte pour configurer votre profil et accéder à toutes les
          fonctionnalités.
        </p>
        <Link
          href="/register"
          className="mt-8 flex h-[52px] w-full items-center justify-center rounded-mboa-lg bg-mboa-primary text-sm font-bold text-white"
        >
          Créer un compte
        </Link>
        <Link
          href="/login"
          className="mt-3 flex h-[52px] w-full items-center justify-center rounded-mboa-lg border-[1.5px] border-mboa-primary text-sm font-bold text-mboa-primary"
        >
          Se connecter
        </Link>
      </div>
    );
  }

  const stats = await getProfilStats(user.id, user.role);

  return <ProfilConnected user={user} stats={stats} />;
}
