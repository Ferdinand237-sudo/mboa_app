"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Dialog } from "@/components/ui/dialog";

// Miroir de _creerAmbassadeur (admin_users_screen.dart).
export function CreateAmbassadeurDialog({ open, onClose }: { open: boolean; onClose: () => void }) {
  const [nom, setNom] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [whatsapp, setWhatsapp] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  function fermer() {
    setNom("");
    setEmail("");
    setPassword("");
    setWhatsapp("");
    setError(null);
    setSuccess(null);
    onClose();
  }

  async function creer() {
    if (!nom.trim()) {
      setError("Nom requis");
      return;
    }
    if (!email.includes("@")) {
      setError("Email invalide");
      return;
    }
    if (password.length < 6) {
      setError("Mot de passe : 6 caractères minimum");
      return;
    }
    setError(null);
    setLoading(true);
    const supabase = createClient();
    try {
      const response = await supabase.functions.invoke("create-ambassadeur", {
        body: { nom: nom.trim(), email: email.trim(), password, whatsapp: whatsapp.trim() },
      });
      if (!response.error) {
        setSuccess(`✅ Ambassadeur ${nom.trim()} créé`);
        setTimeout(fermer, 1400);
      } else {
        setError("Erreur lors de la création");
      }
    } catch {
      setError("Erreur lors de la création");
    } finally {
      setLoading(false);
    }
  }

  return (
    <Dialog open={open} onClose={fermer}>
      <h2 className="text-base font-extrabold text-mboa-text">🧭 Créer un ambassadeur</h2>
      <div className="mt-3 flex flex-col gap-3">
        <Field label="Nom complet" value={nom} onChange={setNom} />
        <Field label="Email" value={email} onChange={setEmail} type="email" />
        <Field label="Mot de passe temporaire" value={password} onChange={setPassword} type="password" />
        <Field label="WhatsApp (optionnel)" value={whatsapp} onChange={setWhatsapp} type="tel" />
      </div>
      {error && <p className="mt-3 text-xs font-semibold text-mboa-danger">{error}</p>}
      {success && <p className="mt-3 text-xs font-semibold text-mboa-primary">{success}</p>}
      <div className="mt-5 flex justify-end gap-3">
        <button type="button" onClick={fermer} className="rounded-mboa-md px-4 py-2 text-sm font-semibold text-mboa-text-muted">
          Annuler
        </button>
        <button
          type="button"
          onClick={creer}
          disabled={loading}
          className="rounded-mboa-md bg-mboa-primary px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
        >
          {loading ? "..." : "Créer le compte"}
        </button>
      </div>
    </Dialog>
  );
}

function Field({
  label,
  value,
  onChange,
  type = "text",
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  type?: string;
}) {
  return (
    <label className="flex flex-col gap-1.5">
      <span className="text-xs font-semibold text-mboa-text">{label}</span>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="rounded-mboa-md border border-mboa-border bg-mboa-background px-3.5 py-2.5 text-sm text-mboa-text outline-none focus:border-2 focus:border-mboa-primary"
      />
    </label>
  );
}
