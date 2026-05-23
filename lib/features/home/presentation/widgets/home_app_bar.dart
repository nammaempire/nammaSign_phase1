import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/brand_logo.dart';

/// Home top bar: hamburger menu (left), centered NammaSign mark + brand
/// text, notification bell with unread dot (right).
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          _IconButton(
            icon: Icons.menu_rounded,
            onTap: () => context.showSnack('Menu drawer (Phase 1b)'),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandLogo(
                variant: LogoVariant.mark,
                height: 26,
                color: AppColors.textPrimaryOnLight,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'NammaSign',
                style: AppTextStyles.brandHuge.copyWith(
                  fontSize: 20,
                  color: AppColors.textPrimaryOnLight,
                ),
              ),
            ],
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _IconButton(
                icon: Icons.notifications_none_rounded,
                onTap: () =>
                    context.showSnack('Notifications (Phase 1b)'),
                bordered: false,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String appNameBare() => AppConstants.appName;
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
    this.bordered = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bordered ? AppColors.surfaceLight : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: AppColors.textPrimaryOnLight, size: 22),
        ),
      ),
    );
  }
}
