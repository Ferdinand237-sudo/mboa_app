// Miroir de lib/core/utils/validators.dart — mêmes règles que l'app mobile.

const EMAIL_REGEX =
  /^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/;
const TELEPHONE_REGEX = /^(?:\+?237)?[26][0-9]{8}$/;

export function validateEmail(value: string, required = true): string | null {
  const v = value.trim();
  if (!v) return required ? "Veuillez entrer votre email" : null;
  if (!EMAIL_REGEX.test(v)) return "Format d'email invalide (ex: nom@exemple.com)";
  return null;
}

export function validateTelephone(value: string, required = true): string | null {
  const v = value.replace(/\s/g, "").trim();
  if (!v) return required ? "Veuillez entrer votre numéro" : null;
  if (!TELEPHONE_REGEX.test(v)) return "Numéro invalide (ex: 6XX XXX XXX ou +237 6XX XXX XXX)";
  return null;
}

export function validateMotDePasse(value: string): string | null {
  if (!value) return "Veuillez entrer un mot de passe";
  if (value.length < 8) return "Minimum 8 caractères";
  if (!/[a-zA-Z]/.test(value) || !/[0-9]/.test(value)) {
    return "Le mot de passe doit contenir au moins une lettre et un chiffre";
  }
  return null;
}
