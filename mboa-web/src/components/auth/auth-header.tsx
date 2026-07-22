"use client";

import { useRouter } from "next/navigation";
import { Fragment } from "react";

// Miroir du header dégradé partagé par login_screen.dart, register_screen.dart,
// register_etudiant_screen.dart et demande_vendeur_screen.dart : coins arrondis
// en bas, bouton retour translucide, logo optionnel, titre + sous-titre, et
// indicateur d'étapes optionnel (register étudiant).
export function AuthHeader({
  title,
  subtitle,
  showLogo = false,
  gradientClassName = "from-mboa-primary-dark via-mboa-primary to-mboa-primary-light",
  steps,
}: {
  title: string;
  subtitle: string;
  showLogo?: boolean;
  gradientClassName?: string;
  steps?: { label: string; active: boolean }[];
}) {
  const router = useRouter();

  return (
    <div className={`rounded-b-[32px] bg-gradient-to-br px-6 pb-9 pt-5 ${gradientClassName}`}>
      <button
        onClick={() => router.back()}
        aria-label="Retour"
        className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/20 text-white"
      >
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" className="h-4 w-4">
          <path d="M15 5l-7 7 7 7" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </button>

      {showLogo && (
        <div className="mt-6 flex items-center gap-3">
          <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-white/20 text-xl">
            🏘
          </span>
          <span className="text-[22px] font-extrabold text-white">Mboa</span>
        </div>
      )}

      {steps && (
        <div className="mt-6 flex items-center">
          {steps.map((s, i) => (
            <Fragment key={s.label}>
              {i > 0 && <div className="mb-5 h-[1.5px] flex-1 bg-white/30" />}
              <div className="flex flex-col items-center gap-1">
                <span
                  className={`flex h-7 w-7 items-center justify-center rounded-full text-xs font-bold ${
                    s.active ? "bg-white text-mboa-primary" : "bg-white/30 text-white"
                  }`}
                >
                  {i + 1}
                </span>
                <span
                  className={`text-[10px] ${
                    s.active ? "font-semibold text-white" : "text-white/50"
                  }`}
                >
                  {s.label}
                </span>
              </div>
            </Fragment>
          ))}
        </div>
      )}

      <h1 className={`${showLogo || steps ? "mt-5" : "mt-6"} text-[26px] font-extrabold text-white`}>
        {title}
      </h1>
      <p className="mt-1 text-[13px] text-white/75">{subtitle}</p>
    </div>
  );
}
