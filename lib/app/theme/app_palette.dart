import 'package:flutter/material.dart';

/// Theme-aware semantic colors that swap between light and dark mode.
///
/// Brand colors (purple, status colors, gradients) live in [AppColors] and
/// stay constant across themes — only surfaces, text, and dividers flex.
///
/// Read from anywhere using the `context.colors` extension declared at the
/// bottom of this file:
///
///   ```dart
///   Container(color: context.colors.bg)
///   ```
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.shadow,
  });

  /// Page background — drawn behind the entire scaffold.
  final Color bg;

  /// Subtle elevated surface — used for chip backgrounds, mini-tiles,
  /// section headers. Sits one shade up from `bg`.
  final Color surface;

  /// Card surface — used for the white cards/rows that float on top of
  /// the page. Sits one shade up from `surface`.
  final Color card;

  /// Primary body text — body copy, headlines on light/dark backgrounds.
  final Color textPrimary;

  /// Secondary text — subtitles, supporting copy.
  final Color textSecondary;

  /// Tertiary text — placeholders, hint text, captions.
  final Color textTertiary;

  /// Hairline borders on cards, dividers between rows.
  final Color border;

  /// Shadow tint behind elevated cards.
  final Color shadow;

  // ---------------------------------------------------------------------------
  // Variants
  // ---------------------------------------------------------------------------

  /// The lavender-tinted light palette the app was originally designed in.
  static const AppPalette light = AppPalette(
    bg: Color(0xFFF6F1FA),
    surface: Color(0xFFEDE4FA),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1A1A22),
    textSecondary: Color(0xFF5E5E68),
    textTertiary: Color(0xFF9494A0),
    border: Color(0xFFE5DEF1),
    shadow: Color(0x14000000),
  );

  /// Companion dark palette. Hand-tuned so brand purple still pops against
  /// the deep neutral backgrounds without losing legibility.
  static const AppPalette dark = AppPalette(
    bg: Color(0xFF0E0E14),
    surface: Color(0xFF1A1A22),
    card: Color(0xFF1F1F28),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB8B8C6),
    textTertiary: Color(0xFF6E6E7C),
    border: Color(0xFF2E2E38),
    shadow: Color(0x66000000),
  );

  // ---------------------------------------------------------------------------
  // ThemeExtension boilerplate
  // ---------------------------------------------------------------------------

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? shadow,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

/// Ergonomic access: `context.colors.bg` etc.
extension AppPaletteX on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
