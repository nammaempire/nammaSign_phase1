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
import '../../../auth/data/account_deletion_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../history/domain/booking.dart';
import '../../../history/presentation/providers/bookings_provider.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/providers/theme_mode_provider.dart';
import '../../../notifications/data/notifications_repository.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
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

    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: context.colors.bg,
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
                  children: [
                    _ThemeTile(),
                    _NotificationsTile(),
                    const SettingsTile(
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
                      onTap: () => context.push(AppRoutes.help),
                    ),
                    SettingsTile(
                      icon: Icons.delete_forever_outlined,
                      title: 'Delete account',
                      subtitle: 'Permanently remove your account and data',
                      destructive: true,
                      onTap: () => _confirmDeleteAccount(context, ref),
                    ),
                    SettingsTile(
                      icon: Icons.logout_rounded,
                      title: 'Sign out',
                      destructive: true,
                      onTap: () async {
                        // Remove this device's FCM token first so the user
                        // doesn't keep receiving notifications after sign-out.
                        final me = ref.read(currentUserProvider);
                        if (me != null) {
                          try {
                            await ref
                                .read(notificationsRepositoryProvider)
                                .unregisterCurrentToken(me.id);
                          } catch (_) {
                            // Non-fatal — sign-out continues regardless.
                          }
                        }
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
        color: context.colors.textTertiary,
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
        : context.colors.textTertiary.withValues(alpha: 0.55);
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
        color: context.colors.card,
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
              color: context.colors.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.brandFooter.copyWith(
              color: context.colors.textTertiary,
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

/// Notifications row — taps into the full notifications history screen.
/// Subtitle and trailing badge update live as new notifications arrive.
class _NotificationsTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsCountProvider);
    final subtitle = unread == 0
        ? 'No new notifications'
        : '$unread unread '
            'notification${unread == 1 ? '' : 's'}';
    return SettingsTile(
      icon: unread > 0
          ? Icons.notifications_rounded
          : Icons.notifications_none_rounded,
      title: 'Notifications',
      subtitle: subtitle,
      onTap: () => context.push(AppRoutes.notifications),
      trailing: unread == 0
          ? null
          : Container(
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ),
    );
  }
}

/// Opens a confirmation dialog. The user must type DELETE to enable the
/// destructive action — that's the friction layer that protects against
/// accidental taps and against someone who picked up an unlocked phone.
Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => const _DeleteAccountDialog(),
  );
  if (confirmed != true) return;
  if (!context.mounted) return;

  // Show a non-cancelable progress overlay while the server hard-deletes
  // everything. Even on a fast connection this takes a couple seconds.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DeleteInProgressDialog(),
  );

  try {
    await ref.read(accountDeletionRepositoryProvider).deleteMyAccount();
    // Once the server-side delete completes, the Firebase Auth user no
    // longer exists — sign out locally so the auth-state stream emits null
    // and the router carries us to /login.
    await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss progress
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your account has been deleted.')),
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss progress
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Couldn't delete account"),
        content: Text('$e\n\nPlease try again, or contact support.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Stateful inner dialog — owns the "type DELETE" text controller so we
/// only enable the destructive button once the user has typed the magic
/// string. Cancel button always works.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  static const _confirmWord = 'DELETE';
  final _ctrl = TextEditingController();
  bool get _canConfirm => _ctrl.text.trim().toUpperCase() == _confirmWord;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.warning_amber_rounded,
        size: 36,
        color: Color(0xFFB7245B),
      ),
      title: const Text('Delete your account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "This permanently removes your NammaSign account. Once it's "
            "done it can't be undone.",
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'What will be removed:',
            style: AppTextStyles.labelMedium.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ..._bullets(context, const [
            'Your profile, contact details, and KYC documents',
            'Your booking history (active campaigns will be cancelled)',
            'Notifications and preferences',
          ]),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Type DELETE to confirm:',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'DELETE',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB7245B),
            disabledBackgroundColor: const Color(0xFFB7245B).withValues(
              alpha: 0.4,
            ),
          ),
          onPressed: _canConfirm
              ? () => Navigator.of(context).pop(true)
              : null,
          child: const Text('Delete forever'),
        ),
      ],
    );
  }

  List<Widget> _bullets(BuildContext context, List<String> lines) {
    return [
      for (final line in lines)
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '•  ',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              Expanded(
                child: Text(
                  line,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }
}

/// Modal progress overlay shown while the Cloud Function runs.
class _DeleteInProgressDialog extends StatelessWidget {
  const _DeleteInProgressDialog();
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Deleting your account…',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Theme appearance row — tap opens a bottom sheet with a Light / Dark /
/// System segmented selector. Subtitle reflects the current choice so the
/// user can see at a glance which mode is active without opening it.
class _ThemeTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final (label, icon) = switch (mode) {
      ThemeMode.light => ('Light', Icons.light_mode_rounded),
      ThemeMode.dark => ('Dark', Icons.dark_mode_rounded),
      ThemeMode.system => ('System default', Icons.brightness_auto_rounded),
    };
    return SettingsTile(
      icon: icon,
      title: 'Appearance',
      subtitle: label,
      onTap: () => _showSheet(context, ref),
    );
  }

  Future<void> _showSheet(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        final currentMode = ref.watch(themeModeProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sheet grabber
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetCtx.colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Appearance',
                  style: AppTextStyles.h2.copyWith(
                    color: sheetCtx.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick a theme. NammaSign will remember your choice.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: sheetCtx.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _ThemeOption(
                  mode: ThemeMode.light,
                  current: currentMode,
                  icon: Icons.light_mode_rounded,
                  title: 'Light',
                  subtitle: 'Crisp lavender background, dark text.',
                ),
                const SizedBox(height: 10),
                _ThemeOption(
                  mode: ThemeMode.dark,
                  current: currentMode,
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark',
                  subtitle: 'Easier on the eyes after sundown.',
                ),
                const SizedBox(height: 10),
                _ThemeOption(
                  mode: ThemeMode.system,
                  current: currentMode,
                  icon: Icons.brightness_auto_rounded,
                  title: 'System default',
                  subtitle: 'Match your phone settings automatically.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ThemeOption extends ConsumerWidget {
  const _ThemeOption({
    required this.mode,
    required this.current,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final ThemeMode mode;
  final ThemeMode current;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = mode == current;
    return Material(
      color: selected ? context.colors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await ref.read(themeModeProvider.notifier).set(mode);
          if (context.mounted) Navigator.of(context).pop();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : context.colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : context.colors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: selected
                      ? AppColors.primary
                      : context.colors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? AppColors.primary
                    : context.colors.textTertiary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
