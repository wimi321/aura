import 'package:flutter/material.dart';

class AppTheme {
  // ==========================================
  // CORE SEMANTIC TOKENS
  // ==========================================

  // Backgrounds: The deep, private void. Moving away from cheap blues to OLED-friendly abyss.
  static const Color bgBase = Color(0xFF03070A);
  static const Color bgCard = Color(0xFF0C131A);
  static const Color bgElevated = Color(0xFF151D25);
  static const Color bgOverlay = Color(0xB203070A); // 70% opacity base

  // Foreground Text: Crisp, highly legible.
  static const Color textPrimary = Color(0xFFF2F6F9);
  static const Color textSecondary = Color(0xFFA1B0BC);
  static const Color textMuted = Color(0xFF677986);

  // Accents: The "Eclipse Core" brand elements. Restrained and premium.
  static const Color brandAura =
      Color(0xFF4EE0B5); // Cooler, slightly tempered mint
  static const Color brandCoral = Color(0xFFFAA078); // Restrained coral

  // Status: Unified and normalized against the dark background.
  static const Color statusSuccess = Color(0xFF55D8A4);
  static const Color statusWarning = Color(0xFFFFB668);
  static const Color statusDanger = Color(0xFFF26868);

  // Borders: Pure white with opacity for additive blending on any dark surface.
  static const Color borderSubtle = Color(0x0CFFFFFF); // ~5%
  static const Color borderStrong = Color(0x19FFFFFF); // ~10%

  // Backward-compatible aliases used across older UI files while the
  // design system is being consolidated.
  static const Color ink = bgBase;
  static const Color cardElevated = bgElevated;
  static const Color primary = brandAura;
  static const Color highlight = brandCoral;
  static const Color mist = textSecondary;
  static const Color danger = statusDanger;
  static const Color dangerSoft = Color(0x22F26868);

  static ThemeData get darkTheme {
    // Premium Typography: System native (San Francisco / PingFang on iOS, Roboto / Noto on Android)
    // We strictly control tracking (letterSpacing) and leading (height) for high readability.
    final TextTheme baseTextTheme =
        ThemeData.dark(useMaterial3: true).textTheme;
    final TextTheme premiumTextTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w800, letterSpacing: -1.2, color: textPrimary),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w800, letterSpacing: -0.8, color: textPrimary),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w700, letterSpacing: -0.5, color: textPrimary),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700, letterSpacing: -0.5, color: textPrimary),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600, letterSpacing: -0.3, color: textPrimary),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600, letterSpacing: 0, color: textPrimary),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600, letterSpacing: 0.15, color: textPrimary),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600, letterSpacing: 0.1, color: textPrimary),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.15,
          height: 1.6,
          color: textPrimary),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          height: 1.5,
          color: textPrimary),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          height: 1.4,
          color: textSecondary),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600, letterSpacing: 0.1, color: textPrimary),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: textSecondary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgBase,
      colorScheme: const ColorScheme.dark(
        primary: brandAura,
        secondary: brandCoral,
        surface: bgCard,
        onPrimary: bgBase,
        onSecondary: bgBase,
        onSurface: textPrimary,
        error: statusDanger,
        onError: textPrimary,
      ),
      textTheme: premiumTextTheme,

      // Components
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textPrimary, size: 20),
        titleTextStyle:
            premiumTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: bgElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: borderStrong)),
        titleTextStyle: premiumTextTheme.titleLarge,
        contentTextStyle:
            premiumTextTheme.bodyMedium?.copyWith(color: textSecondary),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: bgElevated,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: bgElevated,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),

      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderSubtle),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCard,
        hintStyle: premiumTextTheme.bodyLarge?.copyWith(color: textMuted),
        labelStyle: premiumTextTheme.bodyMedium?.copyWith(color: textSecondary),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: borderSubtle, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: borderStrong, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandAura,
          foregroundColor: bgBase,
          textStyle: premiumTextTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderStrong),
          textStyle: premiumTextTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textPrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        space: 1,
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgElevated,
        contentTextStyle:
            premiumTextTheme.bodyMedium?.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: borderStrong)),
        behavior: SnackBarBehavior.floating,
        elevation: 10,
      ),
    );
  }
}
