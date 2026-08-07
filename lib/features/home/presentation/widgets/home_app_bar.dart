import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../../app/theme/app_palette.dart';

/// Home top bar: hamburger menu (left), centered Reset95 mark + brand
/// text, notification bell with live unread badge (right).
class HomeAppBar extends ConsumerWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsCountProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Invisible spacer matching the bell button width so the brand
          // mark stays optically centered without the hamburger icon.
          const SizedBox(width: 40),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // No `color:` here — that prop tints the image as a flat
              // colour and would wipe out the gradient on the new mark.
              const BrandLogo(
                variant: LogoVariant.mark,
                height: 30,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Reset95',
                style: AppTextStyles.brandHuge.copyWith(
                  fontSize: 20,
                  color: context.colors.textPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          _BellWithBadge(
            unread: unread,
            onTap: () => context.push(AppRoutes.notifications),
          ),
        ],
      ),
    );
  }

  static String appNameBare() => AppConstants.appName;
}

/// Bell icon with a live unread badge. Shows a small purple dot when 1-9
/// unread and a numbered pill for higher counts (caps at 99+).
class _BellWithBadge extends StatelessWidget {
  const _BellWithBadge({required this.unread, required this.onTap});
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _IconButton(
          icon: unread > 0
              ? Icons.notifications_rounded
              : Icons.notifications_none_rounded,
          onTap: onTap,
          bordered: false,
        ),
        if (unread > 0)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.colors.card, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
    );
  }
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
      color: bordered ? context.colors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: context.colors.textPrimary, size: 22),
        ),
      ),
    );
  }
}
