import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Illustration for onboarding slide 03 — book and go live.
/// A phone mock with a "go live" CTA and a "LIVE IN 1 HR" badge.
class BookingIllustration extends StatelessWidget {
  const BookingIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Phone body
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 130,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.badgeDark, width: 3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    // Notch
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.badgeDark,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Calendar header bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'May 2026',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textPrimaryOnLight,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Calendar dot grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        crossAxisCount: 7,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        children: List.generate(21, (i) {
                          final selected = i == 10 || i == 11 || i == 12;
                          return Container(
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.surfaceLight,
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                    ),
                    const Spacer(),
                    // "Go live" CTA inside phone
                    Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'GO LIVE',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          letterSpacing: 1.5,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Decorative star top-right
          const Positioned(
            top: 0,
            right: 50,
            child: Icon(
              Icons.bolt_rounded,
              color: AppColors.primary,
              size: 32,
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
                    'LIVE',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontFamily: 'monospace',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'IN 1 HOUR',
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
