import type { Metadata } from "next";
import { getAdminSignalements } from "@/lib/data/admin";
import { SignalementsClient } from "@/components/admin/signalements-client";

export const metadata: Metadata = {
  title: "Signalements",
};

// Miroir de AdminSignalementsScreen (admin_signalements_screen.dart).
export default async function AdminSignalementsPage() {
  const signalements = await getAdminSignalements();
  return <SignalementsClient signalements={signalements} />;
}
