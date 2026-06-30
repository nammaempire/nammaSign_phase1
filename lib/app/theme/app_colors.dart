import 'package:flutter/material.dart';

/// Centralized color tokens for NammaSign.
///
/// Palette pulled from the splash screen design — vivid purple primary
/// with a darker variant for gradients and a lighter accent for highlights.
class AppColors {
  AppColors._();

  // ---- Brand (purple) ----
  static const Color primary = Color(0xFF7B2FE3); // Vivid purple
  static const Color primaryDark = Color(0xFF4A1A9C);
  static const Color primaryLight = Color(0xFF9B5BF0);
  static const Color primaryAccent = Color(0xFFC9A8FF); // Soft lavender
  static const Color secondary = Color(0xFFE5D9FF); // Light purple

  // Splash gradient stops — used by the radial gradient on splash screen.
  static const Color splashCenter = Color(0xFF8A3FED);
  static const Color splashMid = Color(0xFF6020C8);
  static const Color splashEdge = Color(0xFF3D0F8A);

  // ---- Surfaces (dark theme) ----
  static const Color background = Color(0xFF0E0E14);
  static const Color surface = Color(0xFF1A1A22);
  static const Color surfaceElevated = Color(0xFF26262F);
  static const Color card = Color(0xFF1F1F28);

  // ---- Surfaces (light - used on onboarding and any light screens) ----
  static const Color backgroundLight = Color(0xffffaf6fe);
  static const Color surfaceLight = Color(0xFFEDE4FA);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color badgeDark = Color(0xFF1A1A22);
  static const Color groundLineLight = Color(0xFFEED9D2);
  static const Color crowdDot = Color(0xFF6E8E1F);

  // ---- Text (dark theme defaults) ----
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8C6);
  static const Color textTertiary = Color(0xFF6E6E7C);
  static const Color textInverse = Color(0xFF0E0E14);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ---- Text (on light surfaces) ----
  static const Color textPrimaryOnLight = Color(0xFF1A1A22);
  static const Color textSecondaryOnLight = Color(0xFF5E5E68);
  static const Color textTertiaryOnLight = Color(0xFF9494A0);

  // ---- Borders / Dividers ----
  static const Color border = Color(0xFF2E2E38);
  static const Color divider = Color(0xFF26262F);

  // ---- Status ----
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ---- Overlays ----
  static const Color overlay = Color(0x99000000);
  static const Color shimmerBase = Color(0xFF2A2A33);
  static const Color shimmerHighlight = Color(0xFF3A3A44);

  // ---- Card border gradient ----
  /// Canonical gradient used by [GradientBorderBox] around every content
  /// card in the app. Soft lavender → vivid purple → deep purple,
  /// diagonal direction so the corners have visible variation.
  static const LinearGradient cardBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC9A8FF), Color(0xFF7B2FE3), Color(0xFF4A1A9C)],
    stops: [0.0, 0.5, 1.0],
  );
}
