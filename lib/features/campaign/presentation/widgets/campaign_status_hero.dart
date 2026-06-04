import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_palette.dart';

/// Shared header used on all 3 campaign-status screens.
///
/// Dashed ring → solid colored circle with icon → status pill →
/// two-line serif title → subtitle paragraph.
class CampaignStatusHero extends StatelessWidget {
  const CampaignStatusHero({
    super.key,
    required this.circleColor,
    required this.icon,
    required this.pillText,
    required this.pillBg,
    required this.pillFg,
    required this.titleLeading,
    required this.titleTrailingItalic,
    required this.subtitle,
    this.dashedRing = true,
    this.iconColor = Colors.white,
    this.titleFontSize = 26,
  });

  final Color circleColor;
  final IconData icon;
  final String pillText;
  final Color pillBg;
  final Color pillFg;
  final String titleLeading;
  final String titleTrailingItalic;
  final Widget subtitle;
  final bool dashedRing;

  /// Colour used to draw the [icon] inside the centre circle. Defaults to
  /// white for solid-coloured circles; the Under Review state passes the
  /// dark amber so the clock reads as outlined on a light cream circle.
  final Color iconColor;

  /// Override for the headline size. The Under Review state uses 32 so the
  /// "Hang tight, we're reviewing." headline wraps onto two lines.
  final double titleFontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (dashedRing)
                CustomPaint(
                  painter: _DashedRingPainter(),
                  size: const Size(140, 140),
                ),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 42),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Status pill
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: pillFg,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                pillText,
                style: AppTextStyles.brandFooter.copyWith(
                  color: pillFg,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Two-line serif title — split first word(s) + italic remainder.
        // Keep them as RichText so wrapping handles long trailing words cleanly.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTextStyles.brandHuge.copyWith(
                fontSize: titleFontSize,
                color: context.colors.textPrimary,
                height: 1.2,
              ),
              children: [
                TextSpan(text: titleLeading),
                TextSpan(
                  text: titleTrailingItalic,
                  style: AppTextStyles.brandHugeItalic.copyWith(
                    fontSize: titleFontSize,
                    color: AppColors.primary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: DefaultTextStyle(
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: context.colors.textSecondary,
              height: 1.5,
            ),
            child: subtitle,
          ),
        ),
      ],
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.black.withValues(alpha: 0.2);
    final radius = size.width / 2 - 4;
    const dashArc = 0.05;
    const gapArc = 0.04;
    var start = 0.0;
    while (start < 6.28318) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: radius,
        ),
        start,
        dashArc,
        false,
        paint,
      );
      start += dashArc + gapArc;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
