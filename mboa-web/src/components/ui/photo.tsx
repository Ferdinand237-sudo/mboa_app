"use client";

import Image from "next/image";
import { useState } from "react";

// Équivalent web de MboaCachedImage : gère l'absence de photo et les
// erreurs de chargement avec un placeholder cohérent avec le thème.
export function Photo({
  src,
  alt,
  className,
}: {
  src: string | undefined | null;
  alt: string;
  className?: string;
}) {
  const [errored, setErrored] = useState(false);

  if (!src || errored) {
    return (
      <div
        className={`flex items-center justify-center bg-mboa-background text-mboa-text-muted ${className ?? ""}`}
      >
        <span className="text-3xl" aria-hidden>
          🏠
        </span>
      </div>
    );
  }

  return (
    <Image
      src={src}
      alt={alt}
      fill
      sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 25vw"
      className={`object-cover ${className ?? ""}`}
      onError={() => setErrored(true)}
    />
  );
}
