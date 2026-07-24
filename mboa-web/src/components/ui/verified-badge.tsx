// Pastille de certification façon réseaux sociaux (contour en sceau à
// crans + coche blanche) plutôt qu'un simple ✅ ou un ✓ dans un rond plat :
// remplace toutes les variantes ad-hoc utilisées jusqu'ici dans le projet.
export function VerifiedBadge({ className = "h-4 w-4" }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" className={className} aria-label="Compte vérifié" role="img">
      <path
        d="M12 1.5 14.9 3.4 18.3 3 19.2 6.3 22.1 8.2 20.9 11.5 22.1 14.8 19.2 16.7 18.3 20 14.9 19.6 12 21.5 9.1 19.6 5.7 20 4.8 16.7 1.9 14.8 3.1 11.5 1.9 8.2 4.8 6.3 5.7 3 9.1 3.4 12 1.5Z"
        className="fill-mboa-verified"
      />
      <path
        d="M8 12.3 10.6 14.9 16 9.5"
        fill="none"
        stroke="white"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
