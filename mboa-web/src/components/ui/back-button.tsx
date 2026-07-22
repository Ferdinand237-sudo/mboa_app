"use client";

import { useRouter } from "next/navigation";

export function BackButton() {
  const router = useRouter();
  return (
    <button
      onClick={() => router.back()}
      aria-label="Retour"
      className="flex h-9 w-9 items-center justify-center rounded-full bg-white/90 text-mboa-text shadow"
    >
      ←
    </button>
  );
}
