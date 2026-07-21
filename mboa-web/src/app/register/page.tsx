"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { AuthHeader } from "@/components/auth/auth-header";
import { GoogleButton } from "@/components/auth/google-button";
import { OrDivider } from "@/components/auth/or-divider";
import { CheckIcon } from "@/components/ui/icons";

type AccountType = {
  icon: string;
  titre: string;
  description: string;
  href: string;
  activeClasses: string;
  iconBg: string;
};

const TYPES: AccountType[] = [
  {
    icon: "🎓",
    titre: "Étudiant / Visiteur",
    description: "Je cherche un logement ou des bons plans",
    href: "/register/etudiant",
    activeClasses: "border-mboa-primary bg-mboa-primary/8",
    iconBg: "bg-mboa-primary/12",
  },
  {
    icon: "🏪",
    titre: "Commerçant / Propriétaire",
    description: "Je veux publier des annonces sur Mboa",
    href: "/register/vendeur",
    activeClasses: "border-mboa-secondary bg-mboa-secondary/8",
    iconBg: "bg-mboa-secondary/12",
  },
];

// Miroir de register_screen.dart : choix du type de compte avant de router
// vers /register/etudiant ou /register/vendeur.
export default function RegisterPage() {
  const router = useRouter();
  const [selected, setSelected] = useState<number | null>(null);

  return (
    <div className="mx-auto max-w-md pb-12">
      <AuthHeader
        showLogo
        title="Créer un compte"
        subtitle="Choisis ton type de compte pour commencer"
      />

      <div className="flex flex-col gap-2 px-6 pt-6">
        <h2 className="text-base font-bold text-mboa-text">Je suis...</h2>
        <p className="text-sm text-mboa-text-muted">Sélectionne le profil qui te correspond</p>

        <div className="mt-3 flex flex-col gap-3.5">
          {TYPES.map((type, i) => {
            const isSelected = selected === i;
            return (
              <button
                key={type.titre}
                type="button"
                onClick={() => setSelected(i)}
                className={`flex items-center gap-3.5 rounded-mboa-lg border-[1.5px] p-[18px] text-left shadow-sm transition-colors ${
                  isSelected ? `border-2 ${type.activeClasses}` : "border-mboa-border bg-mboa-card"
                }`}
              >
                <span className={`flex h-[52px] w-[52px] shrink-0 items-center justify-center rounded-2xl text-2xl ${type.iconBg}`}>
                  {type.icon}
                </span>
                <span className="flex-1">
                  <span
                    className={`block text-sm font-bold ${
                      isSelected
                        ? i === 0
                          ? "text-mboa-primary"
                          : "text-mboa-secondary"
                        : "text-mboa-text"
                    }`}
                  >
                    {type.titre}
                  </span>
                  <span className="mt-0.5 block text-xs text-mboa-text-muted">{type.description}</span>
                </span>
                <span
                  className={`flex h-[22px] w-[22px] shrink-0 items-center justify-center rounded-full border-2 ${
                    isSelected
                      ? i === 0
                        ? "border-mboa-primary bg-mboa-primary text-white"
                        : "border-mboa-secondary bg-mboa-secondary text-white"
                      : "border-mboa-border"
                  }`}
                >
                  {isSelected && <CheckIcon />}
                </span>
              </button>
            );
          })}
        </div>

        <button
          type="button"
          disabled={selected === null}
          onClick={() => selected !== null && router.push(TYPES[selected].href)}
          className="mt-2 flex h-[52px] items-center justify-center rounded-mboa-lg bg-mboa-primary text-sm font-bold text-white disabled:bg-mboa-border disabled:text-mboa-text-muted"
        >
          Continuer
        </button>

        <div className="mt-5">
          <OrDivider />
        </div>

        <div className="mt-5">
          <GoogleButton />
        </div>

        <p className="mt-8 text-center text-sm">
          <span className="text-mboa-text-muted">Déjà un compte ? </span>
          <Link href="/login" className="font-bold text-mboa-primary">
            Se connecter
          </Link>
        </p>
      </div>
    </div>
  );
}
