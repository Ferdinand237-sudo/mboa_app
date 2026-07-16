/// Validateurs de formulaires réutilisables (email, téléphone camerounais).
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
  );

  // Numéros camerounais : mobile (6XXXXXXXX, 9 chiffres) ou fixe (2XXXXXXXX),
  // avec ou sans indicatif +237 / 237, espaces tolérés.
  static final RegExp _telephoneRegex = RegExp(r'^(?:\+?237)?[26][0-9]{8}$');

  /// Retourne un message d'erreur si [value] n'est pas un email valide, sinon null.
  /// [required] : si false, un champ vide est accepté (retourne null).
  static String? email(String? value, {bool required = true}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) {
      return required ? 'Veuillez entrer votre email' : null;
    }
    if (!_emailRegex.hasMatch(v)) {
      return 'Format d\'email invalide (ex: nom@exemple.com)';
    }
    return null;
  }

  /// Retourne un message d'erreur si [value] n'est pas un numéro camerounais valide.
  /// [required] : si false, un champ vide est accepté (retourne null).
  static String? telephone(String? value, {bool required = true}) {
    final v = (value ?? '').replaceAll(' ', '').trim();
    if (v.isEmpty) {
      return required ? 'Veuillez entrer votre numéro' : null;
    }
    if (!_telephoneRegex.hasMatch(v)) {
      return 'Numéro invalide (ex: 6XX XXX XXX ou +237 6XX XXX XXX)';
    }
    return null;
  }

  /// Normalise un numéro saisi vers le format +237XXXXXXXXX pour stockage cohérent.
  static String normaliserTelephone(String value) {
    var v = value.replaceAll(' ', '').replaceAll('-', '').trim();
    if (v.startsWith('+237')) return v;
    if (v.startsWith('237')) return '+$v';
    return '+237$v';
  }

  static bool estEmailValide(String value) => _emailRegex.hasMatch(value.trim());

  static bool estTelephoneValide(String value) =>
      _telephoneRegex.hasMatch(value.replaceAll(' ', '').trim());

  /// Mot de passe : au moins 8 caractères, une lettre et un chiffre.
  static String? motDePasse(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Veuillez entrer un mot de passe';
    if (v.length < 8) return 'Minimum 8 caractères';
    if (!RegExp(r'[a-zA-Z]').hasMatch(v) || !RegExp(r'[0-9]').hasMatch(v)) {
      return 'Le mot de passe doit contenir au moins une lettre et un chiffre';
    }
    return null;
  }
}
