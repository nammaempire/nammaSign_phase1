import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/brand_logo.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';
import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';

const double kWebTopBarHeight = 64;

/// Full-width top navigation bar for the desktop web layout: brand on the
/// left, Home / History / Profile links and the notifications bell on the
/// right. Replaces the mobile bottom tab bar on wide browser windows.
class WebTopBar extends ConsumerWidget {
  const WebTopBar({
    super.key,
    this.showNav = true,
    this.activeIndex,
    this.onNavTap,
  });

  final bool showNav;

  /// Index of the highlighted link (0 Home, 1 History, 2 Profile), or null
  /// when the current page isn't one of the three tabs.
  final int? activeIndex;

  /// Tab-switch handler from the main shell. When null the links navigate
  /// with `context.go`.
  final ValueChanged<int>? onNavTap;

  static const _links = <(String, String)>[
    ('Home', AppRoutes.home),
    ('History', AppRoutes.history),
    ('Profile', AppRoutes.profile),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Material(
      color: colors.card,
      child: Container(
        height: kWebTopBarHeight,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: showNav ? () => context.go(AppRoutes.home) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BrandLogo(variant: LogoVariant.mark, height: 30),
                        const SizedBox(width: 10),
                        Text(
                          'Reset95',
                          style: AppTextStyles.brandHuge.copyWith(
                            fontSize: 20,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (showNav) ...[
                  for (var i = 0; i < _links.length; i++)
                    _NavLink(
                      label: _links[i].$1,
                      active: activeIndex == i,
                      onTap: () {
                        final handler = onNavTap;
                        if (handler != null) {
                          handler(i);
                        } else {
                          context.go(_links[i].$2);
                        }
                      },
                    ),
                  const SizedBox(width: 12),
                  _Bell(
                    unread: ref.watch(unreadNotificationsCountProvider),
                    onTap: () => context.push(AppRoutes.notifications),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : context.colors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: active
                ? AppColors.primary.withValues(alpha: 0.10)
                : Colors.transparent,
          ),
          child: Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: color,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({required this.unread, required this.onTap});

  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifications',
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: unread > 0,
        backgroundColor: AppColors.primary,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: Icon(
          unread > 0
              ? Icons.notifications_rounded
              : Icons.notifications_none_rounded,
          color: context.colors.textPrimary,
        ),
      ),
    );
  }
}
