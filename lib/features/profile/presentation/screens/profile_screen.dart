import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../account_type/domain/account_type.dart';
import '../../../account_type/presentation/providers/account_type_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

/// Profile tab — avatar + identity header, grouped settings sections,
/// and a sign-out action at the bottom.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.backgroundLight,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    final user = ref.watch(currentUserProvider);
    final type = ref.watch(persistedAccountTypeProvider) ??
        AccountType.corporate;

    // Phase 1a: pull display values from the fake user where we can, fall
    // back to demo data for things we don't actually capture yet.
    final name = user?.displayName ?? 'Priya Menon';
    final org = type == AccountType.corporate
        ? 'Brigade Enterprises'
        : 'Personal Account';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xxl,
            AppSpacing.xxl,
            AppSpacing.xxxl,
          ),
          children: [
            ProfileHeader(
              name: name,
              accountTypeLabel: type.displayLabel,
              orgLabel: org,
            ),

            const SizedBox(height: AppSpacing.xxxl),
            Divider(
              color: AppColors.primary.withValues(alpha: 0.1),
              height: 1,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ACCOUNT
            SettingsSection(
              title: 'Account',
              children: [
                SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Personal info',
                  subtitle: 'Name, email, manager phone',
                  onTap: () =>
                      context.showSnack('Personal info (Phase 1b)'),
                ),
                SettingsTile(
                  icon: Icons.credit_card_rounded,
                  title: 'Payment methods',
                  subtitle: '2 UPI · 1 card linked',
                  onTap: () =>
                      context.showSnack('Payment methods (Phase 1b)'),
                ),
                SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'KYC documents',
                  subtitle: type == AccountType.corporate
                      ? 'PAN, CIN'
                      : 'Aadhaar',
                  subtitleSuffix: 'VERIFIED',
                  onTap: () =>
                      context.showSnack('KYC documents (Phase 1b)'),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxl),

            // PREFERENCES
            SettingsSection(
              title: 'Preferences',
              children: [
                SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Status updates, billing alerts',
                  showChevron: false,
                  onTap: () =>
                      context.showSnack('Notification prefs (Phase 1b)'),
                ),
                SettingsTile(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'English · India',
                  onTap: () => context.showSnack('Language (Phase 1b)'),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxl),

            // SUPPORT
            SettingsSection(
              title: 'Support',
              children: [
                SettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & FAQs',
                  onTap: () => context.showSnack('Help & FAQs (Phase 1b)'),
                ),
                SettingsTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  destructive: true,
                  onTap: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    // Router redirects to /login automatically.
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
