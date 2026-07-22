import type { ReactNode } from "react";

const VARIANTS = {
  verified: "bg-mboa-verified/15 text-mboa-verified",
  boost: "bg-mboa-boost/15 text-mboa-boost",
  neutral: "bg-mboa-background text-mboa-text-muted border border-mboa-border",
  danger: "bg-mboa-danger/15 text-mboa-danger",
} as const;

export function Badge({
  children,
  variant = "neutral",
}: {
  children: ReactNode;
  variant?: keyof typeof VARIANTS;
}) {
  return (
    <span
      className={`inline-flex items-center gap-1 rounded-mboa-full px-2.5 py-1 text-[11px] font-bold tracking-wide ${VARIANTS[variant]}`}
    >
      {children}
    </span>
  );
}
