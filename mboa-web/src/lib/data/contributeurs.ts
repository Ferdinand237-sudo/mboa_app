import { createClient } from "@/lib/supabase/server";
import { userFromRow, type UserModel } from "@/lib/types/models";

// Miroir de _charger (contributeurs_screen.dart).
export async function getTousContributeurs(): Promise<UserModel[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("users")
    .select()
    .eq("role", "vendeur")
    .eq("actif", true)
    .order("verified", { ascending: false })
    .order("boosted", { ascending: false })
    .order("note_globale", { ascending: false })
    .order("nb_avis", { ascending: false });

  if (error || !data) {
    console.error("getTousContributeurs", error?.message);
    return [];
  }
  return data.map(userFromRow);
}
