import type { Metadata } from "next";
import { getCurrentUser } from "@/lib/data/auth";
import { getNotifications } from "@/lib/data/notifications";
import { PageHeader } from "@/components/ui/page-header";
import { NotificationsList } from "@/components/profil/notifications-list";

export const metadata: Metadata = {
  title: "Notifications",
};

// Miroir de notifications_screen.dart.
export default async function NotificationsPage() {
  const user = await getCurrentUser();
  const notifications = user ? await getNotifications(user.id) : [];

  return (
    <div>
      <PageHeader title="🔔 Notifications" />
      <NotificationsList notifications={notifications} />
    </div>
  );
}
