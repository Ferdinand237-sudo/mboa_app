"use server";

import { cookies } from "next/headers";
import { revalidatePath } from "next/cache";
import { VILLE_COOKIE } from "@/lib/data/villes";

// Écrit la ville choisie (sélecteur manuel ou détection GPS automatique,
// voir VilleAutoDetect) dans un cookie plutôt qu'un state client : chaque
// page (accueil, logements, marketplace, carte) est un Server Component
// indépendant qui doit lire la même valeur au rendu, pas seulement la page
// courante — miroir de VilleService (SharedPreferences côté mobile).
export async function setVille(nom: string) {
  const cookieStore = await cookies();
  cookieStore.set(VILLE_COOKIE, nom, {
    maxAge: 60 * 60 * 24 * 365,
    path: "/",
    sameSite: "lax",
  });
  revalidatePath("/", "layout");
}
