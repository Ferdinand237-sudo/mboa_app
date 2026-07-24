import type { Metadata } from "next";
import { Poppins } from "next/font/google";
import "./globals.css";
import { Header } from "@/components/layout/header";
import { ConditionalFooter } from "@/components/layout/conditional-footer";

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
        <main className="flex-1 lg:px-6 xl:px-16 2xl:px-32">{children}</main>
        <ConditionalFooter />
      </body>
    </html>
  );
}
