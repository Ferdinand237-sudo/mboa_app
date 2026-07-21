"use client";

import { useState } from "react";
import { Photo } from "@/components/ui/photo";

export function Gallery({ photos, alt }: { photos: string[]; alt: string }) {
  const [active, setActive] = useState(0);

  if (photos.length === 0) {
    return (
      <div className="relative aspect-video w-full overflow-hidden rounded-mboa-xl">
        <Photo src={undefined} alt={alt} />
      </div>
    );
  }

  return (
    <div>
      <div className="relative aspect-video w-full overflow-hidden rounded-mboa-xl">
        <Photo src={photos[active]} alt={`${alt} — photo ${active + 1}`} />
      </div>
      {photos.length > 1 && (
        <div className="mt-3 flex gap-2 overflow-x-auto pb-1">
          {photos.map((photo, index) => (
            <button
              key={photo + index}
              onClick={() => setActive(index)}
              className={`relative h-16 w-20 shrink-0 overflow-hidden rounded-mboa-md border-2 transition-colors ${
                index === active ? "border-mboa-primary" : "border-transparent"
              }`}
            >
              <Photo src={photo} alt={`${alt} — miniature ${index + 1}`} />
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
