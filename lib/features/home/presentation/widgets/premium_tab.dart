import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/upload_area.dart' show DottedBorder;
import '../../../../app/theme/app_palette.dart';

/// Premium tab — coming soon teaser with feature card + notify-me card.
class PremiumTab extends StatelessWidget {
  const PremiumTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ),
      children: [
        // "★ COMING SOON" pill — centered
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.badgeDark,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'COMING SOON',
                  style: AppTextStyles.brandFooter.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Two-line serif headline, centered
        Text(
          'High-traffic.',
          textAlign: TextAlign.center,
          style: AppTextStyles.brandHuge.copyWith(
            fontSize: 36,
            color: context.colors.textPrimary,
            height: 1.1,
          ),
        ),
        Text(
          'High-impact.',
          textAlign: TextAlign.center,
          style: AppTextStyles.brandHugeItalic.copyWith(
            fontSize: 36,
            color: AppColors.primary,
            height: 1.1,
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        Text(
          'Iconic locations. Massive footfall. Reserved for the brands '
          'that move the city.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(
            color: context.colors.textSecondary,
            height: 1.5,
          ),
        ),

        const SizedBox(height: AppSpacing.xxxl),

        // Dark purple feature card
        _PremiumFeatureCard(),

        const SizedBox(height: AppSpacing.lg),

        // Dashed notify-me card
        _NotifyMeCard(),
      ],
    );
  }
}

class _PremiumFeatureCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.badgeDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "PREMIUM TIER · Q3 2026"
          Text(
            'PREMIUM TIER  ·  Q3 2026',
            style: AppTextStyles.brandFooter.copyWith(
              color: AppColors.primary,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Text(
            'Airports, metros &',
            style: AppTextStyles.brandHuge.copyWith(
              fontSize: 22,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
          Text(
            'flagship junctions.',
            style: AppTextStyles.brandHugeItalic.copyWith(
              fontSize: 22,
              color: AppColors.primaryAccent,
              height: 1.15,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // 2x2 feature grid
          Row(
            children: [
              Expanded(child: _Feature(label: 'BLR Airport')),
              Expanded(child: _Feature(label: 'Metro stations')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _Feature(label: 'MG Road')),
              Expanded(child: _Feature(label: 'Tech Park hubs')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_rounded, size: 18, color: AppColors.success),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotifyMeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      color: AppColors.primary.withValues(alpha: 0.35),
      strokeWidth: 1.4,
      dashWidth: 5,
      dashGap: 5,
      radius: AppSpacing.radiusLg,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get early access',
                    style: AppTextStyles.brandHuge.copyWith(
                      fontSize: 16,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "We'll ping you when Premium goes live",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Material(
              color: AppColors.badgeDark,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: InkWell(
                onTap: () => context.showSnack(
                  "You'll be notified at launch",
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Text(
                    'Notify\nme',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
