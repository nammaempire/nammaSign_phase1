import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_border_box.dart';
import '../../../../app/theme/app_palette.dart';

/// Grouped settings card with an uppercase section header above.
///
/// Children should be [SettingsTile]s. A thin divider is auto-rendered
/// between adjacent tiles.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.brandFooter.copyWith(
              color: context.colors.textTertiary,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GradientBorderBox(
          borderRadius: AppSpacing.radiusLg,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 72),
                    child: Container(
                      height: 0.5,
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
