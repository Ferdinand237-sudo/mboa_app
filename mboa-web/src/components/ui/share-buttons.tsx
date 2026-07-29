"use client";

import { useState } from "react";

// Icônes officielles minimales en SVG inline plutôt qu'une dépendance
// supplémentaire (react-icons etc.) pour 4 pictos statiques.
function IconWhatsapp() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className="h-5 w-5">
      <path d="M17.47 14.38c-.29-.15-1.72-.85-1.99-.94-.27-.1-.46-.15-.66.15-.2.29-.76.94-.93 1.13-.17.2-.34.22-.63.07-.29-.15-1.22-.45-2.32-1.43-.86-.76-1.44-1.71-1.6-2-.17-.29-.02-.45.13-.6.13-.13.29-.34.44-.51.15-.17.19-.29.29-.49.1-.2.05-.37-.02-.51-.07-.15-.66-1.6-.91-2.19-.24-.58-.48-.5-.66-.51h-.56c-.2 0-.51.07-.78.37-.27.29-1.02 1-1.02 2.44s1.04 2.83 1.19 3.03c.15.2 2.05 3.13 4.96 4.39.69.3 1.23.48 1.65.61.69.22 1.32.19 1.82.11.55-.08 1.72-.7 1.96-1.38.24-.68.24-1.26.17-1.38-.07-.12-.27-.2-.56-.35z" />
      <path d="M12.02 2C6.5 2 2.03 6.48 2.03 12c0 1.87.51 3.63 1.4 5.14L2 22l4.98-1.3a9.96 9.96 0 0 0 5.04 1.36c5.52 0 10-4.48 10-10s-4.5-10.06-10-10.06zm0 18.15a8.1 8.1 0 0 1-4.14-1.14l-.3-.18-3.07.8.82-3-.2-.31A8.15 8.15 0 1 1 20.15 12c0 4.5-3.65 8.15-8.13 8.15z" />
    </svg>
  );
}

function IconFacebook() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className="h-5 w-5">
      <path d="M13.5 21v-7.5H16l.4-3H13.5V8.4c0-.87.24-1.46 1.5-1.46h1.6V4.28C16.3 4.2 15.4 4.1 14.36 4.1c-2.15 0-3.63 1.31-3.63 3.72v2.68H8.3v3h2.43V21z" />
    </svg>
  );
}

function IconX() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className="h-5 w-5">
      <path d="M13.6 10.6 20 3h-1.9l-5.5 6.6L8 3H3l6.7 9.6L3 21h1.9l5.9-7.1L16.5 21H21l-7.4-10.4Zm-2.1 2.5-.7-1L5 4.4h2.1l4.4 6.2.7 1 5.8 8.1h-2.1z" />
    </svg>
  );
}

function IconInstagram() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className="h-5 w-5">
      <path d="M12 2.2c2.7 0 3 0 4 .05 1 .05 1.7.2 2.3.45.6.25 1.1.6 1.6 1.1s.85 1 1.1 1.6c.25.6.4 1.3.45 2.3.05 1 .05 1.3.05 4s0 3-.05 4c-.05 1-.2 1.7-.45 2.3-.25.6-.6 1.1-1.1 1.6s-1 .85-1.6 1.1c-.6.25-1.3.4-2.3.45-1 .05-1.3.05-4 .05s-3 0-4-.05c-1-.05-1.7-.2-2.3-.45a4.6 4.6 0 0 1-1.6-1.1 4.6 4.6 0 0 1-1.1-1.6c-.25-.6-.4-1.3-.45-2.3-.05-1-.05-1.3-.05-4s0-3 .05-4c.05-1 .2-1.7.45-2.3.25-.6.6-1.1 1.1-1.6s1-.85 1.6-1.1c.6-.25 1.3-.4 2.3-.45 1-.05 1.3-.05 4-.05M12 0C9.28 0 8.94 0 7.87.06c-1.06.05-1.79.22-2.43.47a6.8 6.8 0 0 0-2.46 1.6A6.8 6.8 0 0 0 1.38 4.6c-.25.64-.42 1.37-.47 2.43C.85 8.1.85 8.45.85 11.16v1.68c0 2.72 0 3.06.06 4.13.05 1.06.22 1.79.47 2.43a6.8 6.8 0 0 0 1.6 2.46 6.8 6.8 0 0 0 2.46 1.6c.64.25 1.37.42 2.43.47 1.07.06 1.41.06 4.13.06s3.06 0 4.13-.06c1.06-.05 1.79-.22 2.43-.47a6.8 6.8 0 0 0 2.46-1.6 6.8 6.8 0 0 0 1.6-2.46c.25-.64.42-1.37.47-2.43.06-1.07.06-1.41.06-4.13V11.16c0-2.71 0-3.06-.06-4.13-.05-1.06-.22-1.79-.47-2.43a6.8 6.8 0 0 0-1.6-2.46A6.8 6.8 0 0 0 19.56.53c-.64-.25-1.37-.42-2.43-.47C16.06 0 15.72 0 13 0Z" />
      <path d="M12 5.84A6.16 6.16 0 1 0 18.16 12 6.16 6.16 0 0 0 12 5.84Zm0 10.16A4 4 0 1 1 16 12a4 4 0 0 1-4 4Z" />
      <circle cx="18.4" cy="5.6" r="1.44" />
    </svg>
  );
}

// Partage social avec preview de carte (meta Open Graph/Twitter posées côté
// serveur par generateMetadata dans la page appelante — voir logements/[id]
// et marketplace/[id]). WhatsApp/Facebook/X ont un intent web officiel ;
// Instagram n'en propose aucun (l'app mobile ne consomme pas de lien
// pré-rempli), d'où le repli sur le partage natif du système (qui liste
// Instagram parmi les cibles sur mobile) ou, à défaut, la copie du lien.
export function ShareButtons({ url, title }: { url: string; title: string }) {
  const [copie, setCopie] = useState(false);

  const encodedUrl = encodeURIComponent(url);
  const encodedTitle = encodeURIComponent(title);

  async function partagerInstagram() {
    if (typeof navigator !== "undefined" && navigator.share) {
      try {
        await navigator.share({ title, url });
        return;
      } catch {
        return;
      }
    }
    await navigator.clipboard.writeText(url);
    setCopie(true);
    setTimeout(() => setCopie(false), 2000);
  }

  const liens = [
    {
      label: "WhatsApp",
      href: `https://wa.me/?text=${encodedTitle}%20-%20${encodedUrl}`,
      icon: <IconWhatsapp />,
      className: "bg-[#25D366] text-white",
    },
    {
      label: "Facebook",
      href: `https://www.facebook.com/sharer/sharer.php?u=${encodedUrl}`,
      icon: <IconFacebook />,
      className: "bg-[#1877F2] text-white",
    },
    {
      label: "X",
      href: `https://twitter.com/intent/tweet?text=${encodedTitle}&url=${encodedUrl}`,
      icon: <IconX />,
      className: "bg-black text-white",
    },
  ];

  return (
    <div className="rounded-mboa-lg border border-mboa-border bg-mboa-card p-4">
      <p className="text-sm font-bold text-mboa-text">📤 Partager cette annonce</p>
      <div className="mt-3 flex items-center gap-2.5">
        {liens.map((l) => (
          <a
            key={l.label}
            href={l.href}
            target="_blank"
            rel="noopener noreferrer"
            aria-label={`Partager sur ${l.label}`}
            className={`flex h-10 w-10 items-center justify-center rounded-full shadow-sm ${l.className}`}
          >
            {l.icon}
          </a>
        ))}
        <button
          onClick={partagerInstagram}
          aria-label="Partager sur Instagram"
          className="flex h-10 w-10 items-center justify-center rounded-full bg-gradient-to-br from-[#FEDA75] via-[#D62976] to-[#4F5BD5] text-white shadow-sm"
        >
          <IconInstagram />
        </button>
        {copie && <span className="text-xs font-semibold text-mboa-primary">Lien copié !</span>}
      </div>
    </div>
  );
}
