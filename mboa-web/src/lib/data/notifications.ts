import { createClient } from "@/lib/supabase/server";

// Miroir web de la table notifications (voir migration
// 20260724000000_notifications_inapp.sql) : alimentée par des triggers SQL
// sur messages/avis/logements/articles, en parallèle du push FCM mobile
// (lib/core/services/notification_service.dart côté app).
export type NotificationRow = {
  id: string;
  type: "message" | "avis" | "annonce";
  titre: string;
  corps: string | null;
  lien: string | null;
  lu: boolean;
  createdAt: string;
};

export async function getNotifications(userId: string): Promise<NotificationRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("notifications")
    .select("id, type, titre, corps, lien, lu, created_at")
    .eq("user_id", userId)
    .order("created_at", { ascending: false })
    .limit(30);

  if (error || !data) return [];

  return data.map((row) => ({
    id: row.id,
    type: row.type,
    titre: row.titre,
    corps: row.corps,
    lien: row.lien,
    lu: row.lu,
    createdAt: row.created_at,
  }));
}

export async function getUnreadNotificationsCount(userId: string): Promise<number> {
  const supabase = await createClient();
  const { count, error } = await supabase
    .from("notifications")
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId)
    .eq("lu", false);

  if (error) return 0;
  return count ?? 0;
}
