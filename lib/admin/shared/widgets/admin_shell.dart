import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../app/admin_routes.dart';
import '../theme/admin_theme.dart';

/// Two-pane layout: persistent left rail + main content area.
class AdminShell extends ConsumerWidget {
  const AdminShell({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.actions = const [],
    required this.section,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final AdminSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SideRail(
            section: section,
            onSignOut: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  title: title,
                  subtitle: subtitle,
                  actions: actions,
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.xxl),
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: AdminText.h1.copyWith(fontSize: 22)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AdminText.bodyMedium),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({required this.section, required this.onSignOut});
  final AdminSection section;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AdminColors.sidebarBg,
        border: Border(right: BorderSide(color: AdminColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand mark
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AdminColors.primary,
                        AdminColors.primaryDeep,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NammaSign',
                      style: AdminText.h1.copyWith(fontSize: 18),
                    ),
                    Text(
                      'ADMIN',
                      style: AdminText.caps.copyWith(
                        fontSize: 10,
                        color: AdminColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Section label
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text('OVERVIEW', style: AdminText.caps),
          ),
          _NavItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            selected: section == AdminSection.dashboard,
            onTap: (ctx) => ctx.go(AdminRoutes.dashboard),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text('OPERATIONS', style: AdminText.caps),
          ),
          _NavItem(
            icon: Icons.inbox_outlined,
            label: 'Bookings',
            selected: section == AdminSection.bookings,
            onTap: (ctx) => ctx.go(AdminRoutes.bookings),
          ),
          _NavItem(
            icon: Icons.people_outline_rounded,
            label: 'Users',
            selected: section == AdminSection.users,
            onTap: (ctx) => ctx.go(AdminRoutes.users),
          ),
          _NavItem(
            icon: Icons.location_on_outlined,
            label: 'Areas',
            selected: section == AdminSection.areas,
            onTap: (ctx) => ctx.go(AdminRoutes.areas),
          ),
          _NavItem(
            icon: Icons.account_balance_outlined,
            label: 'Finance',
            selected: section == AdminSection.finance,
            onTap: (ctx) => ctx.go(AdminRoutes.finance),
          ),

          const Spacer(),

          // Sign-out
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminColors.textSecondary,
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final void Function(BuildContext) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected ? AdminColors.primarySurface : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: AdminColors.hover,
          onTap: selected ? null : () => onTap(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? AdminColors.primary
                      : AdminColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: AdminText.label.copyWith(
                    color: selected
                        ? AdminColors.primary
                        : AdminColors.textPrimary,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
