import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

/// 3-segment progress bar showing the user's position in the booking wizard.
/// Filled segments are purple; remaining segments are pale purple.
class BookingProgressBar extends StatelessWidget {
  const BookingProgressBar({
    super.key,
    required this.current,
    this.total = 3,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: i < current
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
