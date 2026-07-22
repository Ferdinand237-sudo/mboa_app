// Icônes ligne minimalistes miroir des Icons.*_outlined de Material utilisés
// dans les écrans d'auth Flutter (email_outlined, lock_outline_rounded, etc.).
// SVG inline pour rester léger (pas de dépendance à une lib d'icônes).

type IconProps = { className?: string };

const base = "h-5 w-5";

export function EmailIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className}>
      <rect x="3" y="5" width="18" height="14" rx="2.5" />
      <path d="m3.5 6.5 8.5 6 8.5-6" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

export function LockIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className}>
      <rect x="5" y="11" width="14" height="9" rx="2.5" />
      <path d="M8 11V7.5a4 4 0 0 1 8 0V11" strokeLinecap="round" />
    </svg>
  );
}

export function PhoneIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className}>
      <path
        d="M6.6 10.8c1.4 2.8 3.8 5.2 6.6 6.6l2.2-2.2c.3-.3.7-.4 1-.2 1.1.4 2.3.6 3.6.6.6 0 1 .4 1 1V20c0 .6-.4 1-1 1C10.4 21 3 13.6 3 4.6c0-.6.4-1 1-1h3.4c.6 0 1 .4 1 1 0 1.3.2 2.5.6 3.6.1.3 0 .7-.2 1L6.6 10.8Z"
        strokeLinejoin="round"
      />
    </svg>
  );
}

export function PersonIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className}>
      <circle cx="12" cy="8" r="3.5" />
      <path d="M4.5 20c1.2-3.6 4-5.5 7.5-5.5s6.3 1.9 7.5 5.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

export function EyeIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className}>
      <path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12Z" strokeLinejoin="round" />
      <circle cx="12" cy="12" r="2.8" />
    </svg>
  );
}

export function EyeOffIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className}>
      <path
        d="M3.5 3.5l17 17M10.6 10.7a2.8 2.8 0 0 0 3.9 3.9M7.4 7.5C5.2 8.9 3.6 11 2.5 12c0 0 3.5 6.5 9.5 6.5 1.7 0 3.2-.5 4.5-1.2M16.9 16.6C19.2 15.1 20.9 13 21.5 12c0 0-1.4-2.6-4-4.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

export function SendIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className}>
      <path d="M21 3 3 10.5l7 3 3 7L21 3Z" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

export function CheckIcon({ className = "h-3.5 w-3.5" }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" className={className}>
      <path d="m5 12.5 5 5L19 7" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

export function HeartIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={className}>
      <path d="M12 20.5s-7.5-4.6-10-9.4C.4 7.6 2.3 4 6 4c2 0 3.5 1 6 3.5C14.5 5 16 4 18 4c3.7 0 5.6 3.6 4 7.1-2.5 4.8-10 9.4-10 9.4Z" />
    </svg>
  );
}

export function BellIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={className}>
      <path d="M12 22c1.2 0 2.2-.9 2.4-2.1h-4.8c.2 1.2 1.2 2.1 2.4 2.1Zm7-5.4V11c0-3.3-2-6-5.2-6.8V3.3a1.8 1.8 0 0 0-3.6 0v.9C7 5 5 7.7 5 11v5.6L3 18.6v1H21v-1l-2-2Z" />
    </svg>
  );
}

export function ChatIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={className}>
      <path d="M4 4h16a1 1 0 0 1 1 1v11a1 1 0 0 1-1 1H9l-5 4.5V17H4a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1Z" />
    </svg>
  );
}

export function StarIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={className}>
      <path d="M12 2.5 15 9l7 .9-5.1 4.9 1.3 7-6.2-3.4-6.2 3.4 1.3-7L2 9.9 9 9l3-6.5Z" />
    </svg>
  );
}

export function StorefrontIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className}>
      <path d="M3.5 8.5 5 3.5h14l1.5 5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M4 8.5v11h16v-11" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M3.5 8.5a2.5 2.5 0 0 0 5 0 2.5 2.5 0 0 0 5 0 2.5 2.5 0 0 0 5 0 2.5 2.5 0 0 0 2-1" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M9.5 19.5V14h5v5.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

export function AddBusinessIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className}>
      <path d="M4 8.5 5.2 3.5h13.6L20 8.5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M4.5 8.5V20h15V8.5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M9.5 20v-5h5v5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M12 11v4M10 13h4" strokeLinecap="round" />
    </svg>
  );
}

export function ShieldIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className}>
      <path d="M12 3.5 19 6v5.5c0 4.5-3 7.8-7 9-4-1.2-7-4.5-7-9V6l7-2.5Z" strokeLinejoin="round" />
    </svg>
  );
}

export function HelpIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className}>
      <circle cx="12" cy="12" r="9" />
      <path d="M9.5 9.3a2.5 2.5 0 1 1 3.6 2.3c-.8.4-1.1 1-1.1 1.9" strokeLinecap="round" />
      <circle cx="12" cy="16.8" r="0.15" fill="currentColor" stroke="none" />
    </svg>
  );
}

export function InfoIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className}>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 11v5.5" strokeLinecap="round" />
      <circle cx="12" cy="7.8" r="0.15" fill="currentColor" stroke="none" />
    </svg>
  );
}

export function LogoutIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className}>
      <path d="M9 4H5.5A1.5 1.5 0 0 0 4 5.5v13A1.5 1.5 0 0 0 5.5 20H9" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M14.5 16.5 19 12l-4.5-4.5M19 12H9" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

export function EditIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className}>
      <path d="M4 20h4L18.5 9.5a2 2 0 0 0 0-2.8L17.3 5.5a2 2 0 0 0-2.8 0L4 16v4Z" strokeLinejoin="round" />
      <path d="M13 7.5 16.5 11" strokeLinecap="round" />
    </svg>
  );
}

export function ChevronRightIcon({ className = "h-3.5 w-3.5" }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" className={className}>
      <path d="m9 5 7 7-7 7" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

export function CameraIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className}>
      <path d="M4 8h3l1.5-2h7L17 8h3a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1Z" strokeLinejoin="round" />
      <circle cx="12" cy="13.5" r="3.3" />
    </svg>
  );
}

export function TrashIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className}>
      <path d="M5 7h14M9.5 7V5a1 1 0 0 1 1-1h3a1 1 0 0 1 1 1v2M7 7l1 13h8l1-13" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

export function PlusIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" className={className}>
      <path d="M12 5v14M5 12h14" strokeLinecap="round" />
    </svg>
  );
}

export function SearchIcon({ className = base }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className}>
      <circle cx="11" cy="11" r="6.5" />
      <path d="m20 20-4.3-4.3" strokeLinecap="round" />
    </svg>
  );
}
