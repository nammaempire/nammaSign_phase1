import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/app_prefs_provider.dart';
import '../../domain/account_type.dart';
import '../providers/account_type_provider.dart';

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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.backgroundLight,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _onContinue() async {
    final type = ref.read(selectedAccountTypeProvider);
    final mode = GoRouterState.of(context).uri.queryParameters[
            AppRoutes.accountTypeModeParam] ??
        AppRoutes.accountTypeModeOnboarding;

    // Persist the chosen type + (idempotently) mark onboarding complete.
    // markComplete updates both prefs AND the in-memory notifier so the
    // router redirect sees the new state for the next navigation.
    await ref.read(onboardingSeenProvider.notifier).markComplete(
          accountType: type.storageValue,
        );
    if (!mounted) return;

    // Branch on entry mode.
    //
    // Signup flow: PUSH so back goes signup → account-type → login.
    // Onboarding flow: GO so login replaces the stack (no back to
    // onboarding once you're past it).
    if (mode == AppRoutes.accountTypeModeSignup) {
      context.push(
        type == AccountType.corporate
            ? AppRoutes.signupCorporate
            : AppRoutes.signupIndividual,
      );
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedAccountTypeProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
                          const Icon(
                            Icons.chevron_left_rounded,
                            size: 20,
                            color: AppColors.textPrimaryOnLight,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'BACK',
                            style: AppTextStyles.brandFooter.copyWith(
                              color: AppColors.textPrimaryOnLight,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
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
                        color: AppColors.textPrimaryOnLight,
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
                        color: AppColors.textSecondaryOnLight,
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
        child: AnimatedContainer(
          duration: AppConstants.shortAnim,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceLight : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.12),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.cardLight
                      : AppColors.surfaceLight,
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
                        color: AppColors.textPrimaryOnLight,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondaryOnLight,
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
                        : AppColors.textTertiaryOnLight,
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
