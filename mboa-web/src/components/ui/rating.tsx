export function Rating({ note, nbAvis }: { note: number; nbAvis?: number }) {
  if (!note || (nbAvis !== undefined && nbAvis === 0)) {
    return <span className="text-xs text-mboa-text-muted">Pas encore d&apos;avis</span>;
  }
  return (
    <span className="inline-flex items-center gap-1 text-xs font-semibold text-mboa-text">
      <span aria-hidden>⭐</span>
      {note.toFixed(1)}
      {nbAvis !== undefined && (
        <span className="font-normal text-mboa-text-muted">({nbAvis})</span>
      )}
    </span>
  );
}
