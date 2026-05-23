import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

/// 3-card duration picker (e.g. 7 / 15 / 30 days).
/// Selected card flips to dark fill + white text; unselected stay outlined.
class DurationSelector extends StatelessWidget {
  const DurationSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  /// Each option carries days + an optional discount label.
  final List<DurationOption> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _DurationCard(
              option: options[i],
              selected: options[i].days == selected,
              onTap: () => onChanged(options[i].days),
            ),
          ),
        ],
      ],
    );
  }
}

class DurationOption {
  const DurationOption({required this.days, this.discountLabel});
  final int days;
  final String? discountLabel; // e.g. "SAVE 8%"
}

class _DurationCard extends StatelessWidget {
  const _DurationCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final DurationOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.badgeDark : Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected
                  ? AppColors.badgeDark
                  : AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Text(
                '${option.days}',
                style: AppTextStyles.brandHuge.copyWith(
                  fontSize: 24,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryOnLight,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                option.days == 1 ? 'DAY' : 'DAYS',
                style: AppTextStyles.brandFooter.copyWith(
                  color: selected
                      ? AppColors.textPrimary.withValues(alpha: 0.8)
                      : AppColors.textTertiaryOnLight,
                  letterSpacing: 2,
                ),
              ),
              if (option.discountLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  option.discountLabel!,
                  style: AppTextStyles.brandFooter.copyWith(
                    color: selected
                        ? AppColors.primary
                        : AppColors.primary,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
