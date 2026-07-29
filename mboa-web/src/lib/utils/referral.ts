// Code de parrainage capté depuis ?ref=CODE (voir ReferralCapture, monté
// dans le layout racine) et conservé côté client jusqu'à l'inscription —
// localStorage plutôt qu'un cookie serveur : seul le navigateur en a besoin
// (signUp direct ou insertion dans demandes_compte), et la portée peut
// dépasser une simple session.
const STORAGE_KEY = "mboa_code_parrain";

export function lireCodeParrainStocke(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem(STORAGE_KEY);
}

export function stockerCodeParrain(code: string): void {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(STORAGE_KEY, code.trim().toUpperCase());
}
