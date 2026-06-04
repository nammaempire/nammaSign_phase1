import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../../app/theme/app_palette.dart';

enum LogoVariant { lockup, mark }

/// Brand logo. Loads the actual NammaSign logo from
/// `assets/icons/nammasign_logo.png` (lockup) or `nammasign_mark.png`
/// (mark only). If the asset is missing — e.g. during early development
/// before the file is dropped in — falls back to a stylized "NS" placeholder
/// so the layout doesn't break.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.variant = LogoVariant.mark,
    this.height,
    this.color,
  });

  final LogoVariant variant;

  /// Pixel height. Width auto-scales. Defaults vary by variant.
  final double? height;

  /// Tints the asset (when the source PNG is a single colour). Set
  /// `null` to render the original asset colours unchanged.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final assetPath = variant == LogoVariant.lockup
        ? AppConstants.logoLockup
        : AppConstants.logoMark;
    final h = height ?? (variant == LogoVariant.lockup ? 120 : 44);

    return Image.asset(
      assetPath,
      height: h,
      color: color,
      // The asset file may not exist yet during dev — render a placeholder
      // instead of crashing the build.
      errorBuilder: (_, __, ___) => _Fallback(
        variant: variant,
        height: h,
        color: color ?? context.colors.textPrimary,
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.variant,
    required this.height,
    required this.color,
  });

  final LogoVariant variant;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (variant == LogoVariant.mark) {
      // Simple "NS" tile placeholder
      return Container(
        width: height,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height * 0.18),
        ),
        alignment: Alignment.center,
        child: Text(
          'NS',
          style: AppTextStyles.brandHuge.copyWith(
            fontSize: height * 0.45,
            color: color.computeLuminance() > 0.5
                ? context.colors.textPrimary
                : Colors.white,
            letterSpacing: 1,
          ),
        ),
      );
    }
    // Lockup fallback: stacked mark + brand text + tagline
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Fallback(
          variant: LogoVariant.mark,
          height: height * 0.5,
          color: color,
        ),
        SizedBox(height: height * 0.06),
        Text(
          'NAMMASIGN',
          style: AppTextStyles.brandHuge.copyWith(
            fontSize: height * 0.18,
            color: color,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: height * 0.02),
        Text(
          AppConstants.appBrandSubtitle,
          style: AppTextStyles.brandFooter.copyWith(
            color: color.withValues(alpha: 0.7),
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
