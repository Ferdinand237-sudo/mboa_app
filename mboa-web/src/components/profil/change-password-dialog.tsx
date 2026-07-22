"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Dialog } from "@/components/ui/dialog";
import { TextField } from "@/components/ui/text-field";
import { LockIcon } from "@/components/ui/icons";

// Miroir de _ouvrirChangerMotDePasse (profil_screen.dart).
export function ChangePasswordDialog({ open, onClose }: { open: boolean; onClose: () => void }) {
  const [nouveau, setNouveau] = useState("");
  const [confirm, setConfirm] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  function reset() {
    setNouveau("");
    setConfirm("");
    setError(null);
    setMessage(null);
  }

  async function valider() {
    if (nouveau.length < 6) {
      setError("Minimum 6 caractères");
      return;
    }
    if (nouveau !== confirm) {
      setError("Les mots de passe ne correspondent pas");
      return;
    }
    setError(null);
    setLoading(true);
    const supabase = createClient();
    const { error: updateError } = await supabase.auth.updateUser({ password: nouveau });
    setLoading(false);
    if (updateError) {
      setError("Erreur lors du changement de mot de passe");
      return;
    }
    setMessage("✅ Mot de passe mis à jour");
    setTimeout(() => {
      reset();
      onClose();
    }, 1200);
  }

  return (
    <Dialog
      open={open}
      onClose={() => {
        reset();
        onClose();
      }}
    >
      <h3 className="text-base font-bold text-mboa-text">🔒 Changer le mot de passe</h3>
      {error && <p className="mt-3 text-sm text-mboa-danger">{error}</p>}
      {message && <p className="mt-3 text-sm text-mboa-primary">{message}</p>}
      <div className="mt-4 flex flex-col gap-3">
        <TextField
          type="password"
          placeholder="Nouveau mot de passe"
          value={nouveau}
          onChange={(e) => setNouveau(e.target.value)}
          icon={<LockIcon />}
        />
        <TextField
          type="password"
          placeholder="Confirmer le mot de passe"
          value={confirm}
          onChange={(e) => setConfirm(e.target.value)}
          icon={<LockIcon />}
        />
      </div>
      <div className="mt-6 flex justify-end gap-3">
        <button
          onClick={() => {
            reset();
            onClose();
          }}
          disabled={loading}
          className="px-3 py-2 text-sm font-semibold text-mboa-text-muted disabled:opacity-50"
        >
          Annuler
        </button>
        <button
          onClick={valider}
          disabled={loading}
          className="flex items-center justify-center rounded-mboa-md bg-mboa-primary px-4 py-2 text-sm font-bold text-white disabled:opacity-60"
        >
          {loading ? (
            <span className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
          ) : (
            "Valider"
          )}
        </button>
      </div>
    </Dialog>
  );
}
