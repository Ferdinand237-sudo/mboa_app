import { BackButton } from "@/components/ui/back-button";

// Miroir des AppBar simples Flutter (favoris_screen.dart, edit_profil_screen.dart,
// alertes_recherche_screen.dart, avis_moderation_screen.dart, ...) : fond
// mboa-background, bouton retour, titre en gras.
export function PageHeader({ title }: { title: string }) {
  return (
    <div className="mx-auto flex max-w-2xl items-center gap-3 px-5 py-4">
      <BackButton />
      <h1 className="text-lg font-extrabold text-mboa-text">{title}</h1>
    </div>
  );
}
