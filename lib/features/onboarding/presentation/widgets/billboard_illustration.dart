import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Illustration for onboarding slide 02 — "Reach where eyes actually go".
/// Matches the Figma exactly: dark billboard frame with "LIVE" label,
/// a small purple star, two support legs, a ground line with crowd dots,
/// and a stats badge ("12,000 VIEWS/DAY").
class BillboardIllustration extends StatelessWidget {
  const BillboardIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Billboard screen
          Positioned(
            top: 20,
            left: 40,
            right: 40,
            child: Container(
              height: 130,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary, width: 3),
              ),
              alignment: Alignment.center,
              child: Text(
                'LIVE',
                style: AppTextStyles.brandHuge.copyWith(
                  fontSize: 38,
                  color: AppColors.primaryLight,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          // Purple star top-right
          const Positioned(
            top: 0,
            right: 30,
            child: Icon(
              Icons.star_rounded,
              color: AppColors.primary,
              size: 36,
            ),
          ),

          // Left leg
          Positioned(
            top: 150,
            left: 80,
            child: Container(
              width: 6,
              height: 40,
              color: AppColors.badgeDark,
            ),
          ),
          // Right leg
          Positioned(
            top: 150,
            right: 80,
            child: Container(
              width: 6,
              height: 40,
              color: AppColors.badgeDark,
            ),
          ),

          // Ground line
          Positioned(
            top: 192,
            left: 24,
            right: 24,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.groundLineLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Crowd dots along the ground
          Positioned(
            top: 198,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (_) => const _CrowdDot()),
            ),
          ),

          // Stats badge
          Positioned(
            bottom: -4,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.badgeDark,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '12,000',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontFamily: 'monospace',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'VIEWS/DAY',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryLight,
                      letterSpacing: 1.5,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrowdDot extends StatelessWidget {
  const _CrowdDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.crowdDot,
        shape: BoxShape.circle,
      ),
    );
  }
}
