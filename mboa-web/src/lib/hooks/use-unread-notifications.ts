"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";

// Compteur de notifications non lues, tenu à jour en temps réel (canal dédié
// notif_<userId>, fermé au démontage — même principe que le premier usage du
// temps réel dans le projet, chat_screen.dart/conversation-view.tsx).
export function useUnreadNotifications(userId: string | null, initialCount: number): number {
  const [count, setCount] = useState(initialCount);

  useEffect(() => {
    if (!userId) return;
    const supabase = createClient();

    async function recompter() {
      const { count: c } = await supabase
        .from("notifications")
        .select("id", { count: "exact", head: true })
        .eq("user_id", userId as string)
        .eq("lu", false);
      setCount(c ?? 0);
    }

    const channel = supabase
      .channel(`notif_${userId}`)
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "notifications", filter: `user_id=eq.${userId}` },
        recompter,
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [userId]);

  return count;
}
