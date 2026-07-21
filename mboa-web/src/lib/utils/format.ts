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
