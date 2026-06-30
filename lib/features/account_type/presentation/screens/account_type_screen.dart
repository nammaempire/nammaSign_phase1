import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/gradient_border_box.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../legal/presentation/widgets/consent_footer.dart';
import '../../../user/presentation/providers/user_profile_provider.dart';
import '../../domain/account_type.dart';
import '../providers/account_type_provider.dart';
import '../../../../app/theme/app_palette.dart';

/// "How will you advertise?" — user picks Corporate or Individual.
/// Sits between onboarding and login. Persists choice to SharedPreferences
/// and marks onboarding complete before navigating to /login.
class AccountTypeScreen extends ConsumerStatefulWidget {
  const AccountTypeScreen({super.key});

  @override
  ConsumerState<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends ConsumerState<AccountTypeScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _onContinue() async {
    final type = ref.read(selectedAccountTypeProvider);
    final user = ref.read(currentUserProvider);

    if (user == null) {
      // Defensive — shouldn't happen because router gates here only
      // after sign-in. Bounce back to login if it does.
      context.go(AppRoutes.login);
      return;
    }

    // Persist accountType to Firestore. The signup form (next screen)
    // will fill in the rest of the profile fields and finalize setup.
    try {
      await ref
          .read(userProfileRepositoryProvider)
          .setAccountType(user.id, type);
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnack('Could not save account type: $e');
      return;
    }

    if (!mounted) return;
    // Push to the signup form. Back navigation: signup → account-type.
    context.push(
      type == AccountType.corporate
          ? AppRoutes.signupCorporate
          : AppRoutes.signupIndividual,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedAccountTypeProvider);

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — back button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.onboarding),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chevron_left_rounded,
                            size: 20,
                            color: context.colors.textPrimary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'BACK',
                            style: AppTextStyles.brandFooter.copyWith(
                              color: context.colors.textPrimary,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Escape hatch — lets users bail out if they got stuck
                  // partway through setup. Signs them out so the next
                  // launch starts at /login.
                  InkWell(
                    onTap: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      if (!context.mounted) return;
                      context.go(AppRoutes.login);
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Text(
                        'SIGN OUT',
                        style: AppTextStyles.brandFooter.copyWith(
                          color: context.colors.textTertiary,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How will you',
                      style: AppTextStyles.brandHuge.copyWith(
                        fontSize: 36,
                        color: context.colors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'advertise?',
                      style: AppTextStyles.brandHugeItalic.copyWith(
                        fontSize: 36,
                        color: AppColors.primary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Choose the account that fits you. You can always '
                      'switch later in profile.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: context.colors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),

                    // Corporate card
                    _AccountTypeCard(
                      type: AccountType.corporate,
                      icon: Icons.business_center_outlined,
                      title: 'Corporate',
                      description: 'For brands, agencies & businesses. '
                          'PAN/CIN verification, multi-day campaigns.',
                      selected: selected == AccountType.corporate,
                      onTap: () => ref
                          .read(selectedAccountTypeProvider.notifier)
                          .state = AccountType.corporate,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Individual card
                    _AccountTypeCard(
                      type: AccountType.individual,
                      icon: Icons.person_outline_rounded,
                      title: 'Individual',
                      description: 'Birthdays, proposals, shoutouts. '
                          'Aadhaar verified · single-day slots.',
                      selected: selected == AccountType.individual,
                      onTap: () => ref
                          .read(selectedAccountTypeProvider.notifier)
                          .state = AccountType.individual,
                    ),
                  ],
                ),
              ),
            ),

            // Continue CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                0,
                AppSpacing.xxl,
                AppSpacing.xxl,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue with ${selected.displayLabel}',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 22,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Consent footer — same line shown on login. Sits under the
            // primary CTA per Apple's HIG recommendation.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.lg,
              ),
              child: ConsentFooter(
                textColor: context.colors.textTertiary,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selectable card. Selected state: lavender background + 2px purple border
/// + filled purple check. Unselected: white background + thin border +
/// empty circle.
class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({
    required this.type,
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final AccountType type;
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: GradientBorderBox(
          borderRadius: AppSpacing.radiusLg,
          borderWidth: selected ? 1.8 : 1.0,
          innerColor:
              selected ? context.colors.surface : context.colors.card,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: selected
                      ? context.colors.card
                      : context.colors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 28,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),

              // Title + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.brandHuge.copyWith(
                        fontSize: 20,
                        color: context.colors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Selection indicator
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : context.colors.textTertiary,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
