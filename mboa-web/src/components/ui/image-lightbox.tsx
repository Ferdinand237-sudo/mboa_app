"use client";

import { useEffect, useRef, useState } from "react";
import Image from "next/image";

const SEUIL_FERMETURE_PX = 100;

// Visionneuse plein écran : clic sur une photo pour l'agrandir, fermeture en
// glissant vers le bas (l'image suit le doigt puis se ferme au-delà d'un
// seuil, sinon revient à sa place) ou via la croix. Navigation gauche/droite
// si plusieurs photos.
export function ImageLightbox({
  photos,
  alt,
  initialIndex,
  onClose,
}: {
  photos: string[];
  alt: string;
  initialIndex: number;
  onClose: () => void;
}) {
  const [index, setIndex] = useState(initialIndex);
  const [dragY, setDragY] = useState(0);
  const [isDragging, setIsDragging] = useState(false);
  const startY = useRef(0);

  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === "Escape") onClose();
      if (e.key === "ArrowRight") setIndex((i) => (i + 1) % photos.length);
      if (e.key === "ArrowLeft") setIndex((i) => (i - 1 + photos.length) % photos.length);
    }
    window.addEventListener("keydown", onKeyDown);
    document.body.style.overflow = "hidden";
    return () => {
      window.removeEventListener("keydown", onKeyDown);
      document.body.style.overflow = "";
    };
  }, [onClose, photos.length]);

  function onTouchStart(e: React.TouchEvent) {
    setIsDragging(true);
    startY.current = e.touches[0].clientY;
  }

  function onTouchMove(e: React.TouchEvent) {
    const delta = e.touches[0].clientY - startY.current;
    if (delta > 0) setDragY(delta);
  }

  function onTouchEnd() {
    setIsDragging(false);
    if (dragY > SEUIL_FERMETURE_PX) {
      onClose();
    } else {
      setDragY(0);
    }
  }

  const opacity = Math.max(1 - dragY / 400, 0.4);

  return (
    <div
      className="fixed inset-0 z-[70] flex items-center justify-center bg-black"
      style={{ backgroundColor: `rgba(0,0,0,${opacity})` }}
      onClick={onClose}
    >
      <button
        type="button"
        onClick={(e) => {
          e.stopPropagation();
          onClose();
        }}
        aria-label="Fermer"
        className="absolute right-4 top-4 z-10 flex h-10 w-10 items-center justify-center rounded-full bg-white/15 text-xl text-white"
      >
        ✕
      </button>

      {photos.length > 1 && (
        <div className="absolute top-4 left-1/2 z-10 -translate-x-1/2 rounded-mboa-full bg-black/50 px-3 py-1 text-xs font-semibold text-white">
          {index + 1} / {photos.length}
        </div>
      )}

      {photos.length > 1 && (
        <>
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              setIndex((i) => (i - 1 + photos.length) % photos.length);
            }}
            aria-label="Photo précédente"
            className="absolute left-2 top-1/2 z-10 flex h-10 w-10 -translate-y-1/2 items-center justify-center rounded-full bg-white/15 text-xl text-white sm:left-4"
          >
            ‹
          </button>
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              setIndex((i) => (i + 1) % photos.length);
            }}
            aria-label="Photo suivante"
            className="absolute right-2 top-1/2 z-10 flex h-10 w-10 -translate-y-1/2 items-center justify-center rounded-full bg-white/15 text-xl text-white sm:right-4"
          >
            ›
          </button>
        </>
      )}

      <div
        className="relative h-full w-full touch-none"
        onClick={(e) => e.stopPropagation()}
        onTouchStart={onTouchStart}
        onTouchMove={onTouchMove}
        onTouchEnd={onTouchEnd}
        style={{ transform: `translateY(${dragY}px)`, transition: isDragging ? "none" : "transform 0.2s" }}
      >
        <Image src={photos[index]} alt={alt} fill sizes="100vw" className="object-contain" />
      </div>
    </div>
  );
}
