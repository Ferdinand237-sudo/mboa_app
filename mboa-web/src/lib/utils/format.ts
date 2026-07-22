// Miroir des getters prixFormate / initiales des modèles Dart.

export function formatPrix(prix: number): string {
  const entier = Math.round(prix).toString();
  const avecEspaces = entier.replace(/\B(?=(\d{3})+(?!\d))/g, " ");
  return `${avecEspaces} FCFA`;
}

export function initiales(nom: string): string {
  const parts = nom.trim().split(/\s+/).filter(Boolean);
  if (parts.length >= 2) {
    return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
  }
  if (parts.length === 1 && parts[0].length >= 2) {
    return parts[0].slice(0, 2).toUpperCase();
  }
  return (parts[0] ?? "MB").toUpperCase();
}

export function photoPrincipale(photos: string[]): string | undefined {
  return photos.length > 0 ? photos[0] : undefined;
}

export function formatDateFr(iso: string): string {
  return new Date(iso).toLocaleDateString("fr-FR", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });
}

// Miroir de _formatPublicationDate dans article_detail_screen.dart.
export function formatRelativeDate(iso: string): string {
  const diffMs = Date.now() - new Date(iso).getTime();
  const minutes = Math.floor(diffMs / 60000);
  const hours = Math.floor(diffMs / 3600000);
  const days = Math.floor(diffMs / 86400000);

  if (days >= 1) return `Il y a ${days} jour${days > 1 ? "s" : ""}`;
  if (hours >= 1) return `Il y a ${hours} heure${hours > 1 ? "s" : ""}`;
  if (minutes >= 1) return `Il y a ${minutes} minute${minutes > 1 ? "s" : ""}`;
  return "À l'instant";
}
