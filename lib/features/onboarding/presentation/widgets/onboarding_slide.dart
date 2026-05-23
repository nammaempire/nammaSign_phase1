import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Data class for a single onboarding slide.
class OnboardingSlideData {
  const OnboardingSlideData({
    required this.illustration,
    required this.titleLine1,
    required this.titleLine2Italic,
    required this.description,
  });

  final Widget illustration;
  final String titleLine1;
  final String titleLine2Italic;
  final String description;
}

/// Single onboarding slide — illustration card, two-line serif title with
/// italic purple second line, and a description paragraph.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({super.key, required this.data});

  final OnboardingSlideData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: data.illustration,
          ),

          const SizedBox(height: AppSpacing.xxxl),

          // Title — two-line serif with italic purple second line
          Text(
            data.titleLine1,
            style: AppTextStyles.brandHuge.copyWith(
              fontSize: 30,
              color: AppColors.textPrimaryOnLight,
              height: 1.1,
            ),
          ),
          Text(
            data.titleLine2Italic,
            style: AppTextStyles.brandHugeItalic.copyWith(
              fontSize: 30,
              color: AppColors.primary,
              height: 1.1,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Description
          Text(
            data.description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondaryOnLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
