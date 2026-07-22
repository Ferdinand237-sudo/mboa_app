"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Dialog } from "@/components/ui/dialog";
import { LogoutIcon } from "@/components/ui/icons";

// Miroir de _showLogoutDialog (profil_screen.dart) : confirmation avant
// déconnexion, la déconnexion locale est forcée même si l'appel réseau échoue.
export function LogoutButton({ variant = "card" }: { variant?: "card" | "simple" | "icon" }) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);

  async function handleLogout() {
    setLoading(true);
    const supabase = createClient();
    try {
      await supabase.auth.signOut();
    } catch {
      // On force la déconnexion locale même si l'appel réseau échoue.
    }
    router.push("/");
    router.refresh();
  }

  return (
    <>
      {variant === "card" ? (
        <button
          onClick={() => setOpen(true)}
          className="flex w-full items-center justify-center gap-2 rounded-mboa-lg border border-mboa-danger/20 bg-mboa-danger/8 py-4 text-[15px] font-bold text-mboa-danger"
        >
          <LogoutIcon className="h-5 w-5" />
          Déconnexion
        </button>
      ) : variant === "icon" ? (
        <button
          onClick={() => setOpen(true)}
          aria-label="Déconnexion"
          className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/20 text-white"
        >
          <LogoutIcon className="h-5 w-5" />
        </button>
      ) : (
        <button
          onClick={() => setOpen(true)}
          className="rounded-mboa-lg border border-mboa-danger px-5 py-2.5 text-sm font-bold text-mboa-danger"
        >
          Déconnexion
        </button>
      )}

      <Dialog open={open} onClose={() => !loading && setOpen(false)}>
        <h3 className="text-lg font-bold text-mboa-text">Déconnexion</h3>
        <p className="mt-2 text-sm text-mboa-text-muted">Es-tu sûr de vouloir te déconnecter ?</p>
        <div className="mt-6 flex justify-end gap-3">
          <button
            onClick={() => setOpen(false)}
            disabled={loading}
            className="px-3 py-2 text-sm font-semibold text-mboa-text-muted disabled:opacity-50"
          >
            Annuler
          </button>
          <button
            onClick={handleLogout}
            disabled={loading}
            className="flex items-center justify-center rounded-mboa-md bg-mboa-danger px-4 py-2 text-sm font-bold text-white disabled:opacity-60"
          >
            {loading ? (
              <span className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
            ) : (
              "Déconnexion"
            )}
          </button>
        </div>
      </Dialog>
    </>
  );
}
