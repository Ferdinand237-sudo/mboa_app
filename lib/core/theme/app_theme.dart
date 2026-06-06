import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════
// COULEURS MBOA
// ════════════════════════════════════════════════════════════
class MboaColors {
  MboaColors._();

  // Primaires
  static const Color primary      = Color(0xFF2D6A4F);
  static const Color primaryDark  = Color(0xFF1B4332);
  static const Color primaryLight = Color(0xFF52B788);

  // Secondaires
  static const Color secondary    = Color(0xFFF4A261);
  static const Color accent       = Color(0xFFE76F51);

  // Neutres
  static const Color background   = Color(0xFFF8F6F0);
  static const Color card         = Color(0xFFFFFFFF);
  static const Color text         = Color(0xFF1A1A2E);
  static const Color textMuted    = Color(0xFF6B7280);
  static const Color border       = Color(0xFFE5E7EB);

  // États
  static const Color boost        = Color(0xFFF59E0B);
  static const Color verified     = Color(0xFF10B981);
  static const Color danger       = Color(0xFFEF4444);
  static const Color success      = Color(0xFF22C55E);
  static const Color warning      = Color(0xFFF59E0B);

  // Dégradés
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, primaryLight],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, accent],
  );
}

// ════════════════════════════════════════════════════════════
// DIMENSIONS
// ════════════════════════════════════════════════════════════
class MboaSizes {
  MboaSizes._();

  // Padding & Margin
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 48.0;

  // Border radius
  static const double radiusSm  = 8.0;
  static const double radiusMd  = 12.0;
  static const double radiusLg  = 16.0;
  static const double radiusXl  = 24.0;
  static const double radiusFull = 100.0;

  // Élévations
  static const double elevationSm = 2.0;
  static const double elevationMd = 6.0;
  static const double elevationLg = 12.0;

  // Icônes
  static const double iconSm  = 16.0;
  static const double iconMd  = 24.0;
  static const double iconLg  = 32.0;
  static const double iconXl  = 48.0;

  // Hauteurs fixes
  static const double buttonHeight     = 52.0;
  static const double inputHeight      = 52.0;
  static const double navBarHeight     = 70.0;
  static const double appBarHeight     = 60.0;
  static const double cardImageHeight  = 180.0;
}

// ════════════════════════════════════════════════════════════
// STYLES DE TEXTE
// ════════════════════════════════════════════════════════════
class MboaTextStyles {
  MboaTextStyles._();

  static const String _font = 'Poppins';

  // Titres
  static const TextStyle h1 = TextStyle(
    fontFamily: _font,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: MboaColors.text,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: MboaColors.text,
    letterSpacing: -0.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: MboaColors.text,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: MboaColors.text,
  );

  // Corps
  static const TextStyle bodyLg = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: MboaColors.text,
    height: 1.6,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: MboaColors.text,
    height: 1.5,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: MboaColors.textMuted,
    height: 1.5,
  );

  // Prix
  static const TextStyle price = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: MboaColors.primary,
    letterSpacing: -0.5,
  );

  static const TextStyle priceSm = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: MboaColors.primary,
  );

  static const TextStyle priceAccent = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: MboaColors.accent,
  );

  // Labels & badges
  static const TextStyle label = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: MboaColors.textMuted,
    letterSpacing: 0.3,
  );

  static const TextStyle badge = TextStyle(
    fontFamily: _font,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  // Boutons
  static const TextStyle button = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonSm = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: MboaColors.textMuted,
  );

  // Muted
  static const TextStyle muted = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: MboaColors.textMuted,
  );
}

// ════════════════════════════════════════════════════════════
// THÈME PRINCIPAL
// ════════════════════════════════════════════════════════════
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(
        seedColor: MboaColors.primary,
        primary: MboaColors.primary,
        secondary: MboaColors.secondary,
        error: MboaColors.danger,
        background: MboaColors.background,
        surface: MboaColors.card,
      ),

      scaffoldBackgroundColor: MboaColors.background,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: MboaColors.card,
        foregroundColor: MboaColors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: MboaColors.text,
        ),
        iconTheme: IconThemeData(color: MboaColors.text),
      ),

      // Bouton principal
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MboaColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, MboaSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
          ),
          elevation: 0,
          textStyle: MboaTextStyles.button,
        ),
      ),

      // Bouton outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MboaColors.primary,
          minimumSize: const Size(double.infinity, MboaSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
          ),
          side: const BorderSide(color: MboaColors.primary, width: 1.5),
          textStyle: MboaTextStyles.button,
        ),
      ),

      // Bouton texte
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MboaColors.primary,
          textStyle: MboaTextStyles.buttonSm,
        ),
      ),

      // Champs de saisie
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MboaColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MboaSizes.md,
          vertical: MboaSizes.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
          borderSide: const BorderSide(color: MboaColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
          borderSide: const BorderSide(color: MboaColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
          borderSide: const BorderSide(color: MboaColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
          borderSide: const BorderSide(color: MboaColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
          borderSide: const BorderSide(color: MboaColors.danger, width: 2),
        ),
        hintStyle: MboaTextStyles.muted,
        labelStyle: MboaTextStyles.body.copyWith(color: MboaColors.textMuted),
        floatingLabelStyle: MboaTextStyles.body.copyWith(
          color: MboaColors.primary,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: MboaColors.textMuted,
        suffixIconColor: MboaColors.textMuted,
        errorStyle: MboaTextStyles.caption.copyWith(color: MboaColors.danger),
      ),

      // Cartes
      cardTheme: CardThemeData(
        color: MboaColors.card,
        elevation: MboaSizes.elevationSm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
        ),
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: 0.08),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: MboaColors.border,
        thickness: 1,
        space: 1,
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MboaColors.card,
        selectedItemColor: MboaColors.primary,
        unselectedItemColor: MboaColors.textMuted,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: MboaColors.background,
        selectedColor: MboaColors.primary.withValues(alpha: 0.15),
        labelStyle: MboaTextStyles.badge.copyWith(color: MboaColors.text),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MboaSizes.radiusFull),
          side: const BorderSide(color: MboaColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: MboaColors.text,
        contentTextStyle: MboaTextStyles.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: MboaColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MboaSizes.radiusXl),
        ),
        titleTextStyle: MboaTextStyles.h3,
        contentTextStyle: MboaTextStyles.body,
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: MboaColors.primary,
        foregroundColor: Colors.white,
        elevation: MboaSizes.elevationMd,
        shape: CircleBorder(),
      ),

      // ProgressIndicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: MboaColors.primary,
        linearTrackColor: MboaColors.border,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return MboaColors.primary;
          }
          return MboaColors.textMuted;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return MboaColors.primary.withValues(alpha: 0.3);
          }
          return MboaColors.border;
        }),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return MboaColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: const BorderSide(color: MboaColors.border, width: 1.5),
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: MboaSizes.md,
          vertical: MboaSizes.xs,
        ),
        iconColor: MboaColors.textMuted,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: MboaColors.text,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: MboaColors.textMuted,
        ),
      ),
    );
  }
}