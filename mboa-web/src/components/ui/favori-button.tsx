"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

// Miroir de _toggleFavori (logement_detail_screen.dart / article_detail_screen.dart).
export function FavoriButton({
  annonceId,
  type,
  initialFavori,
  isLoggedIn,
}: {
  annonceId: string;
  type: "logement" | "article";
  initialFavori: boolean;
  isLoggedIn: boolean;
}) {
  const [favori, setFavori] = useState(initialFavori);
  const [pending, setPending] = useState(false);

  async function toggle() {
    if (!isLoggedIn) {
      window.location.assign("/login");
      return;
    }
    if (pending) return;
    setPending(true);
    const nouveauStatut = !favori;
    setFavori(nouveauStatut);

    const supabase = createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      setFavori(!nouveauStatut);
      setPending(false);
      return;
    }

    const column = type === "logement" ? "logement_id" : "article_id";

    if (nouveauStatut) {
      await supabase.from("favoris").insert({ user_id: user.id, [column]: annonceId });
    } else {
      await supabase
        .from("favoris")
        .delete()
        .eq("user_id", user.id)
        .eq(column, annonceId);
    }
    setPending(false);
  }

  return (
    <button
      onClick={toggle}
      aria-label="Favori"
      className="flex h-9 w-9 items-center justify-center rounded-full bg-white/90 text-mboa-danger shadow"
    >
      {favori ? "♥" : "♡"}
    </button>
  );
}
