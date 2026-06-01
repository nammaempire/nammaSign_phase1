import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../account_type/domain/account_type.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../history/domain/booking.dart';
import '../../../history/presentation/providers/bookings_provider.dart';
import '../../../user/domain/user_profile.dart';
import '../../../user/presentation/providers/user_profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

/// Profile tab — live user identity + grouped settings + sign-out.
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

    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (profile) {
            // Pull display values straight from the Firestore profile.
            // Falls back gracefully if any sub-field is missing.
            final displayName = profile?.bestDisplayName ?? 'Guest';
            final accountType = profile?.accountType;
            final accountTypeLabel = accountType?.displayLabel ?? 'Setup';
            final orgLabel = profile?.bestOrgLabel ??
                (accountType == AccountType.corporate
                    ? 'Set up account'
                    : '');

            // Subtitle for KYC tile — pull from real data when we have it.
            final kycDocsLabel = accountType == AccountType.corporate
                ? 'PAN, CIN'
                : 'Aadhaar';
            final kycStatus = profile?.kycStatus ?? 'none';

            // Subtitle for Personal info tile — list the actual fields
            // that exist on the profile so the user sees what they've
            // already filled in.
            final personalInfoSubtitle = _buildPersonalInfoSubtitle(profile);

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xxl,
                AppSpacing.xxl,
                AppSpacing.xxxl,
              ),
              children: [
                ProfileHeader(
                  name: displayName,
                  accountTypeLabel: accountTypeLabel,
                  orgLabel: orgLabel,
                  verified: kycStatus == 'verified',
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ACCOUNT TYPE — read-only display of the user's choice
                _SectionLabel('ACCOUNT TYPE'),
                const SizedBox(height: AppSpacing.md),
                _AccountTypeChooser(selected: accountType),

                const SizedBox(height: AppSpacing.xxl),

                // DASHBOARD — campaign stat tiles
                _SectionLabel('DASHBOARD'),
                const SizedBox(height: AppSpacing.md),
                const _DashboardGrid(),

                const SizedBox(height: AppSpacing.xxl),
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
                      subtitle: personalInfoSubtitle,
                      onTap: () => context.push(AppRoutes.personalInfo),
                    ),
                    SettingsTile(
                      icon: Icons.description_outlined,
                      title: 'KYC documents',
                      subtitle: kycDocsLabel,
                      subtitleSuffix:
                          kycStatus == 'verified' ? 'VERIFIED' : null,
                      onTap: () =>
                          context.showSnack('KYC documents (Phase 1b)'),
                    ),
                    const SettingsTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Saved payment methods',
                      subtitle: 'No methods saved yet — add at checkout',
                      showChevron: false,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl),

                // PREFERENCES
                SettingsSection(
                  title: 'Preferences',
                  children: const [
                    SettingsTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Status updates, billing alerts',
                      showChevron: false,
                    ),
                    SettingsTile(
                      icon: Icons.language_rounded,
                      title: 'Language',
                      subtitle: 'English · India',
                      showChevron: false,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl),

                // SUPPORT
                SettingsSection(
                  title: 'Support',
                  children: [
                    SettingsTile(
                      icon: Icons.mail_outline_rounded,
                      title: 'Contact us',
                      subtitle: 'nammaempire@gmail.com',
                      onTap: () async {
                        await Clipboard.setData(
                          const ClipboardData(
                            text: 'nammaempire@gmail.com',
                          ),
                        );
                        if (context.mounted) {
                          context.showSnack(
                            'Email copied — nammaempire@gmail.com',
                          );
                        }
                      },
                    ),
                    SettingsTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & FAQs',
                      onTap: () =>
                          context.showSnack('Help & FAQs (Phase 1b)'),
                    ),
                    SettingsTile(
                      icon: Icons.logout_rounded,
                      title: 'Sign out',
                      destructive: true,
                      onTap: () async {
                        await ref.read(authRepositoryProvider).signOut();
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _buildPersonalInfoSubtitle(UserProfile? profile) {
    if (profile == null) return 'Tap to add your details';
    final type = profile.accountType;
    if (type == AccountType.corporate) {
      final org = profile.corporate;
      if (org == null) return 'Tap to fill in';
      return 'Manager phone, PAN/CIN, email';
    }
    if (type == AccountType.individual) {
      final personal = profile.individual;
      if (personal == null) return 'Tap to fill in';
      return 'Name, DOB, mobile';
    }
    return 'Tap to add your details';
  }
}

// ---------------------------------------------------------------------------
// Section label — small caps muted heading shared by the new sections.
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.brandFooter.copyWith(
        color: AppColors.textTertiaryOnLight,
        letterSpacing: 2,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account type chooser — read-only display of the user's account flavour.
// Shows both options; the selected one gets a white pill + purple border.
// ---------------------------------------------------------------------------

class _AccountTypeChooser extends StatelessWidget {
  const _AccountTypeChooser({required this.selected});
  final AccountType? selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AccountTypeCell(
              icon: Icons.apartment_outlined,
              label: 'Corporate',
              selected: selected == AccountType.corporate,
            ),
          ),
          Expanded(
            child: _AccountTypeCell(
              icon: Icons.person_outline_rounded,
              label: 'Individual',
              selected: selected == AccountType.individual,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTypeCell extends StatelessWidget {
  const _AccountTypeCell({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    // Picked account type is locked at signup — the other option renders
    // greyed out and is non-interactive.
    final fg = selected
        ? AppColors.primary
        : AppColors.textTertiaryOnLight.withValues(alpha: 0.55);
    return Opacity(
      opacity: selected ? 1.0 : 0.55,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: selected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: fg, size: 26),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard — 2×2 grid of stat tiles computed live from the user's bookings.
// ---------------------------------------------------------------------------

class _DashboardGrid extends ConsumerWidget {
  const _DashboardGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsStreamProvider);
    final stats = bookingsAsync.maybeWhen(
      data: _DashboardStats.from,
      orElse: () => _DashboardStats.empty,
    );

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.05,
      children: [
        _StatTile(
          iconBg: const Color(0xFFEDE7FE),
          iconFg: AppColors.primary,
          icon: Icons.dashboard_outlined,
          value: '${stats.totalAds}',
          label: 'TOTAL ADS\nPOSTED',
        ),
        _StatTile(
          iconBg: const Color(0xFFDEEFC9),
          iconFg: const Color(0xFF3B7F2A),
          icon: Icons.currency_rupee_rounded,
          value: _formatSpent(stats.totalSpent),
          label: 'TOTAL SPENT\nON ADS',
        ),
        _StatTile(
          iconBg: const Color(0xFFFAEBD3),
          iconFg: const Color(0xFFB7791F),
          icon: Icons.adjust_rounded,
          value: '${stats.activeCampaigns}',
          label: 'ACTIVE\nCAMPAIGNS',
        ),
        _StatTile(
          iconBg: const Color(0xFFEDE7FE),
          iconFg: AppColors.primary,
          icon: Icons.task_alt_rounded,
          value: '${stats.completedCampaigns}',
          label: 'COMPLETED\nCAMPAIGNS',
        ),
      ],
    );
  }

  /// 84300 → "₹84k", 1500000 → "₹15L", 750 → "₹750".
  static String _formatSpent(int n) {
    if (n >= 100000) {
      final lakh = n / 100000;
      final s = lakh.toStringAsFixed(lakh >= 10 ? 0 : 1);
      return '₹${s}L';
    }
    if (n >= 1000) return '₹${(n / 1000).toStringAsFixed(0)}k';
    return '₹$n';
  }
}

/// Derived snapshot of dashboard numbers from the user's booking list.
class _DashboardStats {
  const _DashboardStats({
    required this.totalAds,
    required this.totalSpent,
    required this.activeCampaigns,
    required this.completedCampaigns,
  });

  final int totalAds;
  final int totalSpent;
  final int activeCampaigns;
  final int completedCampaigns;

  static const empty = _DashboardStats(
    totalAds: 0,
    totalSpent: 0,
    activeCampaigns: 0,
    completedCampaigns: 0,
  );

  factory _DashboardStats.from(List<Booking> bookings) {
    var posted = 0;
    var spent = 0;
    var active = 0;
    var completed = 0;
    for (final b in bookings) {
      switch (b.status) {
        case BookingStatus.draft:
          // Not really posted yet — skip.
          break;
        case BookingStatus.cancelled:
        case BookingStatus.rejected:
          // Counted as posted (the user did create them) but no spend
          // because they weren't run.
          posted++;
          break;
        case BookingStatus.pending:
        case BookingStatus.pendingPayment:
        case BookingStatus.live:
          posted++;
          spent += b.amount;
          active++;
          break;
        case BookingStatus.completed:
          posted++;
          spent += b.amount;
          completed++;
          break;
      }
    }
    return _DashboardStats(
      totalAds: posted,
      totalSpent: spent,
      activeCampaigns: active,
      completedCampaigns: completed,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.iconBg,
    required this.iconFg,
    required this.icon,
    required this.value,
    required this.label,
  });

  final Color iconBg;
  final Color iconFg;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: iconFg, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.brandHuge.copyWith(
              fontSize: 28,
              color: AppColors.textPrimaryOnLight,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.brandFooter.copyWith(
              color: AppColors.textTertiaryOnLight,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
