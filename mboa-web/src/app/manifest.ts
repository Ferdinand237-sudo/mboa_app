import type { MetadataRoute } from "next";

// Permet "Ajouter à l'écran d'accueil" / "Installer l'app" : une fois
// installé, le raccourci affiche le logo Mboa (icônes ci-dessous) avec
// "Mboa" écrit en dessous (short_name), exactement comme une app native.
export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Mboa — Ton premier ami dans une nouvelle ville",
    short_name: "Mboa",
    description:
      "Trouve un logement et achète/vends des équipements entre étudiants à Sangmelima.",
    start_url: "/",
    display: "standalone",
    background_color: "#F8F6F0",
    theme_color: "#2D6A4F",
    icons: [
      { src: "/icons/icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
      { src: "/icons/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
      { src: "/icons/icon-maskable-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
    ],
  };
}
