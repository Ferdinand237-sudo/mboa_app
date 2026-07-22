import { createClient } from "@/lib/supabase/server";

// Miroir de _charger (alertes_recherche_screen.dart).
export type AlerteItem = {
  id: string;
  type: "logement" | "article";
  libelle: string;
  criteres: Record<string, unknown>;
};

export async function getAlertes(userId: string): Promise<AlerteItem[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("alertes_recherche")
    .select("id, type, libelle, criteres")
    .eq("user_id", userId)
    .order("created_at", { ascending: false });

  if (error || !data) {
    console.error("getAlertes", error?.message);
    return [];
  }

  return data.map((row) => ({
    id: String(row.id),
    type: row.type === "article" ? "article" : "logement",
    libelle: String(row.libelle ?? ""),
    criteres: (row.criteres as Record<string, unknown>) ?? {},
  }));
}
