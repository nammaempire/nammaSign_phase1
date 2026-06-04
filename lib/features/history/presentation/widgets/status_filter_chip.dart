import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_palette.dart';

/// Horizontal filter chip used in the history header.
///
/// Active state: dark pill + white text + small purple count badge.
/// Inactive: white pill with thin border + gray text + gray count badge.
class StatusFilterChip extends StatelessWidget {
  const StatusFilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Active chip stays the brand purple regardless of theme — that's the
    // selection signal. Inactive chip uses the theme-aware card surface so
    // it disappears into the page in dark mode.
    return Material(
      color: active ? AppColors.primary : context.colors.card,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: active
                ? null
                : Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: active ? Colors.white : context.colors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withValues(alpha: 0.22)
                      : context.colors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.brandFooter.copyWith(
                    color: active ? Colors.white : context.colors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
