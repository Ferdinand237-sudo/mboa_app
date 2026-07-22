// Sans ce fichier, la navigation vers /chat (route dynamique, aucun retour
// visuel avant le rendu serveur complet) donne l'impression que le clic n'a
// rien fait — l'utilisateur reclique alors plusieurs fois. Ce loading.tsx
// s'affiche immédiatement pendant que la liste des conversations charge.
export default function ChatLoading() {
  return (
    <div className="flex min-h-[70vh] items-center justify-center">
      <span className="h-8 w-8 animate-spin rounded-full border-[3px] border-mboa-primary border-t-transparent" />
    </div>
  );
}
