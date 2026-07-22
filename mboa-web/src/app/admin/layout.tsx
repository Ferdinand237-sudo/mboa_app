import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";
import { AdminNav } from "@/components/admin/admin-nav";

// Miroir de AdminScreen (admin_screen.dart) : section réservée au rôle admin.
export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const user = await getCurrentUser();
  if (!user || user.role !== "admin") redirect("/");

  return (
    <div>
      <AdminNav />
      {children}
    </div>
  );
}
