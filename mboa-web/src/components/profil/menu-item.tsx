import type { ReactNode } from "react";
import Link from "next/link";
import { ChevronRightIcon } from "@/components/ui/icons";

// Miroir de _buildMenuItem (profil_screen.dart).
export function MenuItem({
  icon,
  iconColorClass,
  iconBgClass,
  label,
  subtitle,
  badge,
  trailing,
  href,
  onClick,
}: {
  icon: ReactNode;
  iconColorClass: string;
  iconBgClass: string;
  label: string;
  subtitle?: string;
  badge?: string | number;
  trailing?: ReactNode;
  href?: string;
  onClick?: () => void;
}) {
  const content = (
    <div className="flex items-center gap-3.5 border-b border-mboa-border/60 px-4 py-3.5 last:border-none">
      <span className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-[10px] ${iconBgClass}`}>
        <span className={iconColorClass}>{icon}</span>
      </span>
      <div className="min-w-0 flex-1">
        <p className="text-sm font-medium text-mboa-text">{label}</p>
        {subtitle && <p className="mt-0.5 truncate text-xs text-mboa-text-muted">{subtitle}</p>}
      </div>
      {trailing ??
        (badge !== undefined ? (
          <span className="shrink-0 rounded-mboa-full bg-mboa-primary/10 px-2.5 py-0.5 text-xs font-bold text-mboa-primary">
            {badge}
          </span>
        ) : (
          <ChevronRightIcon className="h-3.5 w-3.5 shrink-0 text-mboa-text-muted" />
        ))}
    </div>
  );

  if (href) {
    return (
      <Link href={href} className="block">
        {content}
      </Link>
    );
  }
  return (
    <button onClick={onClick} className="block w-full text-left">
      {content}
    </button>
  );
}

export function MenuSection({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div className="mx-5 overflow-hidden rounded-mboa-lg bg-mboa-card shadow-sm">
      <p className="px-4 pb-2 pt-3.5 text-xs font-bold uppercase tracking-wide text-mboa-text-muted">
        {title}
      </p>
      <div className="border-t border-mboa-border">{children}</div>
    </div>
  );
}
