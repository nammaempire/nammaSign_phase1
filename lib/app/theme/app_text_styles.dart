import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Centralized typography.
///
/// Built on Inter via Google Fonts. Swap `GoogleFonts.inter` for a local
/// font family in pubspec.yaml once Figma fonts are confirmed.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _base => GoogleFonts.inter(color: AppColors.textPrimary);
  static TextStyle get _serif =>
      GoogleFonts.playfairDisplay(color: AppColors.textPrimary);

  // ---- Brand display (serif - used on splash and brand moments) ----
  static TextStyle get brandHuge => _serif.copyWith(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: -0.5,
      );
  static TextStyle get brandHugeItalic => _serif.copyWith(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
        height: 1.05,
        letterSpacing: -0.5,
        color: AppColors.secondary,
      );
  static TextStyle get brandTagline => _serif.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        height: 1.4,
        color: AppColors.textPrimary.withValues(alpha: 0.85),
      );
  static TextStyle get brandFooter => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 3,
        color: AppColors.textPrimary.withValues(alpha: 0.75),
      );

  // ---- Display ----
  static TextStyle get displayLarge =>
      _base.copyWith(fontSize: 34, fontWeight: FontWeight.w700, height: 1.2);
  static TextStyle get displayMedium =>
      _base.copyWith(fontSize: 28, fontWeight: FontWeight.w700, height: 1.25);

  // ---- Headings ----
  static TextStyle get h1 =>
      _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3);
  static TextStyle get h2 =>
      _base.copyWith(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3);
  static TextStyle get h3 =>
      _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);

  // ---- Body ----
  static TextStyle get bodyLarge =>
      _base.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodyMedium =>
      _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodySmall => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  // ---- Labels / buttons ----
  static TextStyle get labelLarge =>
      _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
  static TextStyle get labelMedium =>
      _base.copyWith(fontSize: 14, fontWeight: FontWeight.w600);
  static TextStyle get labelSmall =>
      _base.copyWith(fontSize: 12, fontWeight: FontWeight.w500);

  // ---- Caption / overline ----
  static TextStyle get caption => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
      );
}
