"use client";

import { useRef, useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";
import { createClient } from "@/lib/supabase/client";
import { validateTelephone } from "@/lib/utils/validators";
import { TextField, FieldLabel } from "@/components/ui/text-field";
import { PersonIcon, PhoneIcon, CameraIcon } from "@/components/ui/icons";
import { BUCKET_PROFILS, BUCKET_BOUTIQUES } from "@/lib/constants";
import type { UserModel } from "@/lib/types/models";

// Miroir de edit_profil_screen.dart : upload direct vers Supabase Storage
// depuis le navigateur (File API), remplace image_picker + File mobile.
export function EditProfilForm({ user }: { user: UserModel }) {
  const router = useRouter();
  const estContributeur = user.role === "vendeur";

  const [nom, setNom] = useState(user.nom);
  const [telephone, setTelephone] = useState(user.telephone ?? "");
  const [photoProfilFile, setPhotoProfilFile] = useState<File | null>(null);
  const [photoProfilPreview, setPhotoProfilPreview] = useState<string | null>(user.photoUrl);
  const [photoCouvertureFile, setPhotoCouvertureFile] = useState<File | null>(null);
  const [photoCouverturePreview, setPhotoCouverturePreview] = useState<string | null>(
    user.photoCommerce,
  );
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const profilInputRef = useRef<HTMLInputElement>(null);
  const couvertureInputRef = useRef<HTMLInputElement>(null);

  function choisirPhoto(file: File | undefined, couverture: boolean) {
    if (!file) return;
    const url = URL.createObjectURL(file);
    if (couverture) {
      setPhotoCouvertureFile(file);
      setPhotoCouverturePreview(url);
    } else {
      setPhotoProfilFile(file);
      setPhotoProfilPreview(url);
    }
  }

  async function uploadPhoto(file: File, bucket: string, userId: string): Promise<string> {
    const supabase = createClient();
    const fileName = `${userId}/${Date.now()}.jpg`;
    const { error: uploadError } = await supabase.storage
      .from(bucket)
      .upload(fileName, file, { upsert: true });
    if (uploadError) throw uploadError;
    return supabase.storage.from(bucket).getPublicUrl(fileName).data.publicUrl;
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (!nom.trim()) {
      setError("Le nom est requis");
      return;
    }
    const telError = validateTelephone(telephone, false);
    if (telError) {
      setError(telError);
      return;
    }
    setError(null);
    setSaving(true);

    const supabase = createClient();
    const {
      data: { user: authUser },
    } = await supabase.auth.getUser();
    if (!authUser) {
      setSaving(false);
      return;
    }

    try {
      const updates: Record<string, string> = {
        nom: nom.trim(),
        telephone: telephone.trim(),
      };
      if (photoProfilFile) {
        updates.photo_url = await uploadPhoto(photoProfilFile, BUCKET_PROFILS, authUser.id);
      }
      if (photoCouvertureFile) {
        updates.photo_commerce = await uploadPhoto(photoCouvertureFile, BUCKET_BOUTIQUES, authUser.id);
      }
      const { error: updateError } = await supabase.from("users").update(updates).eq("id", authUser.id);
      if (updateError) throw updateError;

      router.push("/profil");
      router.refresh();
    } catch {
      setError("Erreur lors de la mise à jour du profil");
      setSaving(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="mx-auto flex max-w-lg flex-col gap-5 px-5 pb-10">
      {error && (
        <p className="rounded-mboa-md bg-mboa-danger/10 px-4 py-3 text-sm text-mboa-danger">{error}</p>
      )}

      {estContributeur && (
        <div>
          <FieldLabel>Photo de couverture (boutique)</FieldLabel>
          <button
            type="button"
            onClick={() => couvertureInputRef.current?.click()}
            className="mt-2 flex h-[110px] w-full items-center justify-center overflow-hidden rounded-mboa-lg bg-gradient-to-br from-mboa-secondary/25 to-mboa-accent/15"
          >
            {photoCouverturePreview ? (
              <div className="relative h-full w-full">
                <Image
                  src={photoCouverturePreview}
                  alt="Couverture"
                  fill
                  sizes="512px"
                  className="object-cover"
                  unoptimized={photoCouverturePreview.startsWith("blob:")}
                />
              </div>
            ) : (
              <CameraIcon className="h-6 w-6 text-mboa-text-muted" />
            )}
          </button>
          <input
            ref={couvertureInputRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={(e) => choisirPhoto(e.target.files?.[0], true)}
          />
        </div>
      )}

      <div>
        <FieldLabel>Photo de profil</FieldLabel>
        <div className="mt-2 flex justify-center">
          <button
            type="button"
            onClick={() => profilInputRef.current?.click()}
            className="relative flex h-[90px] w-[90px] items-center justify-center rounded-full bg-mboa-primary/10"
          >
            {photoProfilPreview ? (
              <Image
                src={photoProfilPreview}
                alt="Photo de profil"
                fill
                sizes="90px"
                className="rounded-full object-cover"
                unoptimized={photoProfilPreview.startsWith("blob:")}
              />
            ) : (
              <PersonIcon className="h-10 w-10 text-mboa-primary" />
            )}
            <span className="absolute bottom-0 right-0 flex h-7 w-7 items-center justify-center rounded-full bg-mboa-primary text-white">
              <CameraIcon className="h-3.5 w-3.5" />
            </span>
          </button>
        </div>
        <input
          ref={profilInputRef}
          type="file"
          accept="image/*"
          className="hidden"
          onChange={(e) => choisirPhoto(e.target.files?.[0], false)}
        />
      </div>

      <label className="flex flex-col gap-2">
        <FieldLabel>Nom complet</FieldLabel>
        <TextField
          type="text"
          required
          value={nom}
          onChange={(e) => setNom(e.target.value)}
          placeholder="Ton nom complet"
          icon={<PersonIcon />}
        />
      </label>

      <label className="flex flex-col gap-2">
        <FieldLabel>WhatsApp</FieldLabel>
        <TextField
          type="tel"
          value={telephone}
          onChange={(e) => setTelephone(e.target.value)}
          placeholder="+237 6XX XXX XXX"
          icon={<PhoneIcon />}
        />
      </label>

      <button
        type="submit"
        disabled={saving}
        className="mt-3 flex h-[52px] items-center justify-center rounded-mboa-lg bg-mboa-primary text-sm font-bold text-white disabled:opacity-60"
      >
        {saving ? (
          <span className="h-5 w-5 animate-spin rounded-full border-2 border-white border-t-transparent" />
        ) : (
          "Enregistrer"
        )}
      </button>
    </form>
  );
}
