import Link from "next/link";

export function SectionTitle({
  title,
  actionLabel,
  actionHref,
}: {
  title: string;
  actionLabel?: string;
  actionHref?: string;
}) {
  return (
    <div className="flex items-center justify-between">
      <h2 className="text-base font-bold text-mboa-text">{title}</h2>
      {actionLabel && actionHref && (
        <Link
          href={actionHref}
          className="text-xs font-semibold text-mboa-primary"
        >
          {actionLabel} →
        </Link>
      )}
    </div>
  );
}
