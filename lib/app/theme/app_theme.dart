import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Builds the app-wide [ThemeData] for both light and dark modes.
///
/// Surface + text colors come from the [AppPalette] theme extension so
/// screens can call `context.colors.bg`. Brand colors (purple, status
/// colors) stay constant across themes — they're read from [AppColors].
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // Public entry points
  // ---------------------------------------------------------------------------

  static ThemeData get lightTheme => _build(
        Brightness.light,
        AppPalette.light,
      );

  static ThemeData get darkTheme => _build(
        Brightness.dark,
        AppPalette.dark,
      );

  // ---------------------------------------------------------------------------
  // Shared builder — keeps light + dark identical in shape, swapping only
  // the surface and text colors.
  // ---------------------------------------------------------------------------

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    final isLight = brightness == Brightness.light;

    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: AppColors.primaryDark,
        surface: p.surface,
        onSurface: p.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),

      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: p.textPrimary),
        displayMedium:
            AppTextStyles.displayMedium.copyWith(color: p.textPrimary),
        headlineLarge: AppTextStyles.h1.copyWith(color: p.textPrimary),
        headlineMedium: AppTextStyles.h2.copyWith(color: p.textPrimary),
        headlineSmall: AppTextStyles.h3.copyWith(color: p.textPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: p.textPrimary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: p.textPrimary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: p.textSecondary),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: p.textPrimary),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: p.textPrimary),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: p.textSecondary),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h2.copyWith(color: p.textPrimary),
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              )
            : SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: p.textTertiary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: p.border,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: p.textTertiary),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: p.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.labelLarge,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelMedium,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.border),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: AppColors.primary,
        labelStyle: AppTextStyles.labelSmall.copyWith(color: p.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          side: BorderSide(color: p.border),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.textPrimary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: p.bg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),

      extensions: <ThemeExtension<dynamic>>[p],
    );
  }
}
