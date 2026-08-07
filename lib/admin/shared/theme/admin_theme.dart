import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for the Reset95 admin portal.
class AdminColors {
  AdminColors._();

  // Brand
  static const Color primary = Color(0xFF534AB7); // deep purple
  static const Color primaryLight = Color(0xFF7F77DD); // lighter purple accent
  static const Color primarySurface = Color(0xFFEDEBFB); // tinted bg behind active nav
  static const Color primaryDeep = Color(0xFF3C3489); // brand-deep

  // Backgrounds
  static const Color appBg = Color(0xFFFAF8FC); // page background
  static const Color cardBg = Colors.white;
  static const Color sidebarBg = Colors.white;
  static const Color hover = Color(0xFFF4F1FA);

  // Text
  static const Color textPrimary = Color(0xFF1A1A22);
  static const Color textSecondary = Color(0xFF5F5E5A);
  static const Color textMuted = Color(0xFF888780);

  // Borders
  static Color border = Colors.black.withValues(alpha: 0.08);
  static Color borderStrong = Colors.black.withValues(alpha: 0.12);

  // Semantic
  static const Color success = Color(0xFF3B7F2A);
  static const Color successBg = Color(0xFFDAF5E0);
  static const Color warning = Color(0xFFB7791F);
  static const Color warningBg = Color(0xFFFCE7C2);
  static const Color danger = Color(0xFFB7245B);
  static const Color dangerBg = Color(0xFFF4DCDF);
  static const Color info = Color(0xFF185FA5);
  static const Color infoBg = Color(0xFFE6F1FB);
}

/// Typography — `Playfair Display` for serif headlines (matches mobile),
/// `Inter` for body. Loaded via google_fonts.
class AdminText {
  AdminText._();

  // Serif headline (for hero numbers, screen titles, brand mark)
  static TextStyle display = GoogleFonts.playfairDisplay(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AdminColors.textPrimary,
    height: 1.1,
  );
  static TextStyle h1 = GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AdminColors.textPrimary,
  );
  static TextStyle metricValue = GoogleFonts.playfairDisplay(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AdminColors.textPrimary,
    height: 1,
  );

  // Inter body
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 15,
    color: AdminColors.textPrimary,
    height: 1.4,
  );
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 13,
    color: AdminColors.textSecondary,
    height: 1.5,
  );
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    color: AdminColors.textMuted,
  );
  static TextStyle label = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AdminColors.textPrimary,
  );
  static TextStyle caps = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
    color: AdminColors.textMuted,
  );
  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}

/// Whitespace scale.
class AdminSpacing {
  AdminSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Material 3 theme tying everything together for `MaterialApp.router`.
ThemeData buildAdminTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AdminColors.primary,
    brightness: Brightness.light,
    primary: AdminColors.primary,
    surface: AdminColors.cardBg,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AdminColors.appBg,
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: AdminColors.textPrimary,
      displayColor: AdminColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AdminColors.cardBg,
      foregroundColor: AdminColors.textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AdminText.label.copyWith(fontSize: 16),
    ),
    cardTheme: CardThemeData(
      color: AdminColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AdminColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AdminColors.cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AdminColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AdminColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AdminColors.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        textStyle: AdminText.buttonText,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        textStyle: AdminText.buttonText,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: AdminColors.border),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AdminColors.textPrimary,
      contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
