import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";

// Miroir de la section Ambassadeur de main_screen.dart. La navigation entre
// onglets vit dans le header (HeaderClient), pas dans une barre horizontale
// séparée ici.
export default async function AmbassadeurLayout({ children }: { children: React.ReactNode }) {
  const user = await getCurrentUser();
  if (!user || user.role !== "ambassadeur") redirect("/");

  return <div>{children}</div>;
}
