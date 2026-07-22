"use server";

import { getLogements } from "@/lib/data/logements";
import { createClient } from "@/lib/supabase/server";
import type { LogementModel } from "@/lib/types/models";

export async function searchLogements(filters: {
  type?: string;
  prixMax?: number;
  search?: string;
}): Promise<LogementModel[]> {
  return getLogements({ ...filters, limit: 200 });
}

export async function enregistrerAlerteLogement(libelle: string, criteres: Record<string, unknown>) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return { error: "not-logged-in" as const };

  const { error } = await supabase.from("alertes_recherche").insert({
    user_id: user.id,
    type: "logement",
    libelle,
    criteres,
  });

  return { error: error ? error.message : null };
}
