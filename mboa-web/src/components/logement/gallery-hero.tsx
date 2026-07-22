"use client";

import { useEffect, useState } from "react";
import { Photo } from "@/components/ui/photo";

// Miroir de _buildGalerie (logement_detail_screen.dart / article_detail_screen.dart) :
// carrousel plein écran avec défilement automatique et compteur.
export function GalleryHero({
  photos,
  alt,
  boosted,
}: {
  photos: string[];
  alt: string;
  boosted?: boolean;
}) {
  const [index, setIndex] = useState(0);

  useEffect(() => {
    if (photos.length <= 1) return;
    const interval = setInterval(() => {
      setIndex((i) => (i + 1) % photos.length);
    }, 4000);
    return () => clearInterval(interval);
  }, [photos.length]);

  return (
    <div className="relative h-[280px] w-full overflow-hidden bg-gradient-to-br from-mboa-primary-dark via-mboa-primary to-mboa-primary-light sm:h-[380px]">
      <Photo src={photos[index]} alt={alt} />

      {photos.length > 1 && (
        <div className="absolute bottom-4 right-4 rounded-mboa-full bg-black/50 px-3 py-1 text-[11px] font-semibold text-white">
          {index + 1} / {photos.length}
        </div>
      )}

      {boosted && (
        <div className="absolute bottom-4 left-4 rounded-mboa-full bg-mboa-boost px-3 py-1.5 text-[10px] font-bold text-white">
          🔥 Annonce boostée
        </div>
      )}
    </div>
  );
}
