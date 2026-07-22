"use client";

import { usePathname } from "next/navigation";
import { Footer } from "./footer";

// Pages où le footer alourdit inutilement l'écran : une conversation
// (interface plein écran façon messagerie) et la carte (plein écran,
// besoin de tout l'espace vertical).
const MASQUER_SUR = [/^\/chat\/.+/, /^\/carte(\/.*)?$/];

export function ConditionalFooter() {
  const pathname = usePathname();
  if (MASQUER_SUR.some((re) => re.test(pathname))) return null;
  return <Footer />;
}
