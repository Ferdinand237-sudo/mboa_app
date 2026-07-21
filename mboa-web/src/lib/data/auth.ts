import { createClient } from "@/lib/supabase/server";
import { userFromRow, type UserModel } from "@/lib/types/models";

// À utiliser dans les Server Components / layouts pour savoir si un
// visiteur est connecté et récupérer son profil (rôle, vérifié, etc.).
export async function getCurrentUser(): Promise<UserModel | null> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return null;

  const { data, error } = await supabase
    .from("users")
    .select()
    .eq("id", user.id)
    .single();

  if (error || !data) return null;

  return userFromRow(data);
}
