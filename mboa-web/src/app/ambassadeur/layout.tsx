import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";

// Miroir de la section Ambassadeur de main_screen.dart : réservée aux
// comptes avec le privilège ambassadeur (role='ambassadeur' historique, ou
// estAmbassadeur superposé à un compte visiteur/vendeur normal). La
// navigation entre onglets vit dans le header (HeaderClient), pas dans une
// barre horizontale séparée ici.
export default async function AmbassadeurLayout({ children }: { children: React.ReactNode }) {
  const user = await getCurrentUser();
  if (!user || !user.estAmbassadeur) redirect("/");

  return <div>{children}</div>;
}
