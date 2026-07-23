import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";

// Miroir de AdminScreen (admin_screen.dart) : section réservée au rôle admin.
// La navigation entre onglets admin vit dans le header (HeaderClient), pas
// dans une barre horizontale séparée ici.
export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const user = await getCurrentUser();
  if (!user || user.role !== "admin") redirect("/");

  return <div>{children}</div>;
}
