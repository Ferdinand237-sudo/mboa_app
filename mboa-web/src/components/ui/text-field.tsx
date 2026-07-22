import type { InputHTMLAttributes, ReactNode, TextareaHTMLAttributes } from "react";

// Miroir de l'InputDecorationTheme Flutter (app_theme.dart) : fond
// mboa-background, bordure 1.5px mboa-border, focus 2px mboa-primary.
type FieldProps = {
  icon?: ReactNode;
  suffix?: ReactNode;
};

export function TextField({
  icon,
  suffix,
  className,
  ...props
}: FieldProps & InputHTMLAttributes<HTMLInputElement>) {
  return (
    <div className="flex items-center gap-2.5 rounded-mboa-md border-[1.5px] border-mboa-border bg-mboa-background px-4 focus-within:border-2 focus-within:border-mboa-primary focus-within:px-[15px]">
      {icon && <span className="shrink-0 text-mboa-text-muted">{icon}</span>}
      <input
        {...props}
        className={`w-full min-w-0 bg-transparent py-3.5 text-sm text-mboa-text outline-none placeholder:text-mboa-text-muted ${className ?? ""}`}
      />
      {suffix}
    </div>
  );
}

export function TextAreaField({
  className,
  ...props
}: TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return (
    <textarea
      {...props}
      className={`w-full rounded-mboa-md border-[1.5px] border-mboa-border bg-mboa-background px-4 py-3.5 text-sm text-mboa-text outline-none placeholder:text-mboa-text-muted focus:border-2 focus:border-mboa-primary focus:px-[15px] focus:py-[13px] ${className ?? ""}`}
    />
  );
}

export function FieldLabel({ children }: { children: ReactNode }) {
  return <span className="text-[13px] font-semibold text-mboa-text">{children}</span>;
}
