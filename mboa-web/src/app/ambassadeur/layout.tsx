import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/auth";
import { AmbassadeurNav } from "@/components/ambassadeur/ambassadeur-nav";

// Miroir de la section Ambassadeur de main_screen.dart.
export default async function AmbassadeurLayout({ children }: { children: React.ReactNode }) {
  const user = await getCurrentUser();
  if (!user || user.role !== "ambassadeur") redirect("/");

  return (
    <div>
      <AmbassadeurNav />
      {children}
    </div>
  );
}
