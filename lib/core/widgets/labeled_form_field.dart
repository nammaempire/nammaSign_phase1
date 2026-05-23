import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

/// Field label row + child input below.
///
/// Used on light-themed signup forms. Renders the field label in
/// uppercase letter-spaced gray with an optional small purple dot on the
/// far right (signals "required" / "active section").
class LabeledFormField extends StatelessWidget {
  const LabeledFormField({
    super.key,
    required this.label,
    required this.child,
    this.showIndicator = true,
  });

  final String label;
  final Widget child;
  final bool showIndicator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.brandFooter.copyWith(
                color: AppColors.textTertiaryOnLight,
                letterSpacing: 2,
              ),
            ),
            if (showIndicator)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}
