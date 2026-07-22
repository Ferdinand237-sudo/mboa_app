import type { Metadata } from "next";
import { getAdminVerifications } from "@/lib/data/admin";
import { VerificationsClient } from "@/components/admin/verifications-client";

export const metadata: Metadata = {
  title: "Vérifications terrain",
};

// Miroir de AdminVerificationsScreen (admin_verifications_screen.dart).
export default async function AdminVerificationsPage() {
  const verifications = await getAdminVerifications();
  return <VerificationsClient verifications={verifications} />;
}
