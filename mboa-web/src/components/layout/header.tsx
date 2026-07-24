import { getCurrentUser } from "@/lib/data/auth";
import { getUnreadNotificationsCount } from "@/lib/data/notifications";
import { HeaderClient } from "./header-client";

export async function Header() {
  const user = await getCurrentUser();
  const unreadCount = user ? await getUnreadNotificationsCount(user.id) : 0;
  return <HeaderClient user={user} unreadCount={unreadCount} />;
}
