import type { Metadata, Viewport } from "next";
import { Poppins } from "next/font/google";
import "./globals.css";
import { Header } from "@/components/layout/header";
import { ConditionalFooter } from "@/components/layout/conditional-footer";
import { InstallPrompt } from "@/components/layout/install-prompt";

const poppins = Poppins({
  variable: "--font-poppins",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800"],
});

export const metadata: Metadata = {
  title: {
    default: "Mboa — Ton premier ami dans une nouvelle ville",
    template: "%s | Mboa",
  },
  description:
    "Mboa aide les étudiants à trouver un logement et à acheter/vendre des équipements à Sangmelima, avant même d'arriver en ville.",
  // "Ajouter à l'écran d'accueil" (iOS) : sans ça Safari propose l'icône par
  // défaut au lieu du logo Mboa. Le nom affiché sous l'icône vient de
  // appleWebApp.title, indépendamment du manifest (lu uniquement par Chrome).
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "Mboa",
  },
  icons: {
    apple: "/apple-touch-icon.png",
  },
};

export const viewport: Viewport = {
  themeColor: "#2D6A4F",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="fr" className={`${poppins.variable} h-full antialiased`}>
      <body className="min-h-full flex flex-col bg-mboa-background text-mboa-text">
        <Header />
        {/* Header/footer restent pleine largeur (leur propre mx-auto max-w-7xl
            centre juste leur contenu) ; seul le contenu central reçoit un
            écart supplémentaire sur grand écran, pour ne plus donner
            l'impression d'un simple zoom sur la version mobile. Rien en
            dessous de lg (1024px) : mobile/tablette restent inchangés. */}
        <main className="flex-1 lg:px-10 xl:px-24 2xl:px-44">{children}</main>
        <ConditionalFooter />
        <InstallPrompt />
      </body>
    </html>
  );
}
