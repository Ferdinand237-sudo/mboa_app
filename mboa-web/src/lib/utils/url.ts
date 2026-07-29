import { headers } from "next/headers";

// Base absolue déduite de la requête entrante (host + protocole), plutôt
// qu'un domaine codé en dur : fonctionne à l'identique en local, sur les
// previews Vercel et en production sans variable d'environnement à tenir à
// jour. Utilisé pour les meta Open Graph/Twitter (aperçu de partage) et les
// liens de partage réseaux sociaux, qui exigent tous deux une URL absolue.
export async function getSiteUrl(): Promise<string> {
  const h = await headers();
  const host = h.get("x-forwarded-host") ?? h.get("host") ?? "localhost:3000";
  const proto = h.get("x-forwarded-proto") ?? (host.startsWith("localhost") ? "http" : "https");
  return `${proto}://${host}`;
}
