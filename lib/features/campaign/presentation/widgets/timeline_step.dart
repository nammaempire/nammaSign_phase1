import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

enum TimelineDotKind {
  /// Solid colored dot (completed / active).
  filled,

  /// Empty outlined circle (pending future step).
  empty,
}

/// One row in the campaign-status timeline list.
///
/// Layout: [dot] + [vertical connector line] | [title + subtitle].
/// The connector line stops on the last step.
class TimelineStep extends StatelessWidget {
  const TimelineStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.dotKind,
    this.dotColor = AppColors.primary,
    this.isLast = false,
    this.titleMuted = false,
    this.highlight,
  });

  final String title;
  final String subtitle;
  final TimelineDotKind dotKind;
  final Color dotColor;
  final bool isLast;
  final bool titleMuted;

  /// Optional extra accent rendered inline at the end of the subtitle
  /// (e.g. "+18% vs avg" in the live state).
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + connector column
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 2),
                _Dot(kind: dotKind, color: dotColor),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: AppColors.primary.withValues(alpha: 0.18),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Title + subtitle column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.brandHuge.copyWith(
                      fontSize: 15,
                      color: titleMuted
                          ? AppColors.textTertiaryOnLight
                          : AppColors.textPrimaryOnLight,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          subtitle,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiaryOnLight,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (highlight != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          highlight!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
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

class _Dot extends StatelessWidget {
  const _Dot({required this.kind, required this.color});
  final TimelineDotKind kind;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isFilled = kind == TimelineDotKind.filled;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: isFilled ? color : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isFilled ? color : AppColors.textTertiaryOnLight,
          width: isFilled ? 0 : 1.5,
        ),
      ),
    );
  }
}
