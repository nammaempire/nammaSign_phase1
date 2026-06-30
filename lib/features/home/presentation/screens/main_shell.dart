import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_palette.dart';

/// Bottom-tab shell used as the root for all signed-in routes.
/// Three tabs per design: Home, History, Profile.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = <_TabSpec>[
    _TabSpec(icon: Icons.home_rounded, label: 'HOME', route: AppRoutes.home),
    _TabSpec(
      icon: Icons.access_time_rounded,
      label: 'HISTORY',
      route: AppRoutes.history,
    ),
    _TabSpec(
      icon: Icons.person_outline_rounded,
      label: 'PROFILE',
      route: AppRoutes.profile,
    ),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bg,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.bg,
            border: const Border(
              top: BorderSide(color: AppColors.divider, width: 0.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _TabButton(
                    spec: _tabs[i],
                    active: navigationShell.currentIndex == i,
                    onTap: () => _onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.icon,
    required this.label,
    required this.route,
  });
  final IconData icon;
  final String label;
  final String route;
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.spec,
    required this.active,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.primary
        : context.colors.textTertiary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top indicator line — small purple bar above active tab
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: active ? 28 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Icon(spec.icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              spec.label,
              style: AppTextStyles.brandFooter.copyWith(
                color: color,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
