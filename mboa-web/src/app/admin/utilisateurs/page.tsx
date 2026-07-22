import type { Metadata } from "next";
import { getAdminUsers } from "@/lib/data/admin";
import { UsersClient } from "@/components/admin/users-client";

export const metadata: Metadata = {
  title: "Utilisateurs",
};

// Miroir de AdminUsersScreen (admin_users_screen.dart).
export default async function AdminUtilisateursPage() {
  const users = await getAdminUsers();
  return <UsersClient users={users} />;
}
