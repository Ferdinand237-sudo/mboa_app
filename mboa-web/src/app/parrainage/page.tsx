import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";
import { getResumeParrainage } from "@/lib/data/parrainage";
import { PageHeader } from "@/components/ui/page-header";
import { ShareButtons } from "@/components/ui/share-buttons";
import { PalierProgression } from "@/components/parrainage/palier-progression";
import { EchelleParrainage } from "@/components/parrainage/echelle-parrainage";
import { ListeFilleuls } from "@/components/parrainage/liste-filleuls";
import { getSiteUrl } from "@/lib/utils/url";

export const metadata: Metadata = {
  title: "Mon parrainage",
};

// Phase 2 de la stratégie de croissance (voir HISTORIQUE_PROJET_MBOA.md) :
// un seul niveau de parrainage, crédits gagnés uniquement après une action
// réelle du filleul (voir migration 20260731000000_parrainage.sql), jamais
// à la simple inscription.
export default async function ParrainagePage() {
  const user = await getCurrentUser();
  if (!user) redirect("/login");

  const [resume, siteUrl] = await Promise.all([getResumeParrainage(user.id), getSiteUrl()]);
  const lienParrainage = `${siteUrl}/?ref=${user.codeParrainage}`;

  return (
    <div className="pb-8">
      <PageHeader title="🎁 Mon parrainage" />

      <div className="mx-auto max-w-2xl px-5">
        <div className="rounded-mboa-lg bg-gradient-to-br from-mboa-primary-dark to-mboa-primary p-5 text-white">
          <p className="text-xs text-white/80">Ton code de parrainage</p>
          <p className="mt-1 text-2xl font-extrabold tracking-widest">{user.codeParrainage}</p>
          <p className="mt-2 text-sm text-white/90">
            Chaque personne inscrite avec ton code te rapporte des crédits : 10 pour un(e)
            étudiant(e), 30 pour un vendeur/propriétaire.
          </p>
        </div>

        <div className="mt-4">
          <ShareButtons url={lienParrainage} title="Rejoins-moi sur Mboa 🏘" />
        </div>

        <div className="mt-6">
          <PalierProgression
            credits={resume.credits}
            palierActuel={resume.palierActuel}
            palierSuivant={resume.palierSuivant}
          />
        </div>

        <div className="mt-7">
          <h2 className="text-base font-bold text-mboa-text">🪜 Les paliers</h2>
          <div className="mt-3">
            <EchelleParrainage paliers={resume.paliers} credits={resume.credits} />
          </div>
        </div>

        <div className="mt-7">
          <h2 className="text-base font-bold text-mboa-text">
            👥 Tes filleuls ({resume.filleuls.length})
          </h2>
          <div className="mt-3">
            <ListeFilleuls filleuls={resume.filleuls} />
          </div>
        </div>
      </div>
    </div>
  );
}
