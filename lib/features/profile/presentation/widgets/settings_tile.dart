import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_palette.dart';

/// One row inside a [SettingsSection].
///
/// - Leading icon in a lavender square.
/// - Title (bold) + optional subtitle.
/// - Trailing widget (defaults to chevron when [onTap] is non-null).
/// - Destructive style for sign-out / delete actions.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleSuffix,
    this.subtitleSuffixColor,
    this.onTap,
    this.trailing,
    this.destructive = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? subtitleSuffix; // e.g. "VERIFIED" rendered after subtitle in colour
  final Color? subtitleSuffixColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final textColor = destructive
        ? const Color(0xFFB7245B)
        : context.colors.textPrimary;
    final iconColor =
        destructive ? const Color(0xFFB7245B) : AppColors.primary;
    final iconBg = destructive
        ? const Color(0xFFFBE3E8)
        : context.colors.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.brandHuge.copyWith(
                        fontSize: 16,
                        color: textColor,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            subtitle!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.colors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                          if (subtitleSuffix != null) ...[
                            Text(
                              '  ·  ',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: context.colors.textTertiary,
                              ),
                            ),
                            Text(
                              subtitleSuffix!,
                              style: AppTextStyles.brandFooter.copyWith(
                                color: subtitleSuffixColor ??
                                    AppColors.success,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (showChevron && !destructive && onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.colors.textTertiary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
