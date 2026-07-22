// Miroir de _parseError dans login_screen.dart / register_etudiant_screen.dart
export function parseAuthError(message: string): string {
  if (message.includes("Invalid login credentials")) {
    return "Email ou mot de passe incorrect";
  }
  if (message.includes("Email not confirmed")) {
    return "Veuillez confirmer votre email";
  }
  if (message.includes("User already registered")) {
    return "Un compte existe déjà avec cet email";
  }
  if (message.includes("Password should be at least")) {
    return "Mot de passe trop court (min. 6 caractères)";
  }
  if (message.includes("rate limit")) {
    return "Trop de tentatives. Réessayez dans quelques minutes.";
  }
  if (message.toLowerCase().includes("invalid")) {
    return "Adresse email refusée par le serveur. Essayez une autre adresse.";
  }
  return "Une erreur est survenue. Réessayez.";
}
