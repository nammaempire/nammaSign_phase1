import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import 'booking_progress_bar.dart';
import '../../../../app/theme/app_palette.dart';

/// BACK + STEP X/3 row, with progress bar underneath.
class BookingTopBar extends StatelessWidget {
  const BookingTopBar({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.home),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: context.colors.textPrimary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'BACK',
                        style: AppTextStyles.brandFooter.copyWith(
                          color: context.colors.textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'STEP ',
                style: AppTextStyles.brandFooter.copyWith(
                  color: context.colors.textTertiary,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '$currentStep',
                style: AppTextStyles.brandFooter.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ' / 3',
                style: AppTextStyles.brandFooter.copyWith(
                  color: context.colors.textTertiary,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          BookingProgressBar(current: currentStep),
        ],
      ),
    );
  }
}
