"use client";

import { Suspense, useEffect } from "react";
import { useSearchParams } from "next/navigation";
import { stockerCodeParrain } from "@/lib/utils/referral";

// Composant invisible monté dans le layout racine (comme InstallPrompt) :
// capte ?ref=CODE sur n'importe quelle page (accueil, une annonce partagée
// via ShareButtons...) et le conserve pour l'inscription, qui peut avoir
// lieu bien après et sur une autre page. Si l'URL ne porte pas de ?ref, le
// code déjà stocké (le cas échéant) n'est pas écrasé.
function ReferralCaptureInner() {
  const searchParams = useSearchParams();
  const ref = searchParams.get("ref");

  useEffect(() => {
    if (ref) stockerCodeParrain(ref);
  }, [ref]);

  return null;
}

export function ReferralCapture() {
  return (
    <Suspense fallback={null}>
      <ReferralCaptureInner />
    </Suspense>
  );
}
