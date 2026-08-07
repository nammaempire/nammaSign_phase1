import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_border_box.dart';
import '../../../account_type/domain/account_type.dart';
import '../../../home/domain/billboard_listing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../user/presentation/providers/user_profile_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/company_details_sheet.dart';
import '../widgets/booking_top_bar.dart';
import '../widgets/selected_board_card.dart';
import '../../../../app/theme/app_palette.dart';

/// Step 1 of the booking flow. Shows the selected billboard at the top,
/// then asks the user whether the booking is corporate or individual.
/// "Continue as Corporate / Individual" navigates to the matching campaign
/// form (step 2).
class BookingAccountTypeScreen extends ConsumerStatefulWidget {
  const BookingAccountTypeScreen({super.key, required this.listing});

  final BillboardListing listing;

  @override
  ConsumerState<BookingAccountTypeScreen> createState() =>
      _BookingAccountTypeScreenState();
}

class _BookingAccountTypeScreenState
    extends ConsumerState<BookingAccountTypeScreen> {
  @override
  void initState() {
    super.initState();
    // Seed the draft once on first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).start(widget.listing);
      // Default selection — corporate, like the design.
      ref.read(bookingProvider.notifier).setType(AccountType.corporate);
    });
  }

  Future<void> _onContinue() async {
    final selected =
        ref.read(bookingProvider).bookingType ?? AccountType.corporate;
    final listingId = widget.listing.id;

    // Individual booking is always allowed with no extra questions —
    // including for corporate-enrolled customers.
    if (selected == AccountType.individual) {
      context.push('${AppRoutes.bookingIndividual}?listingId=$listingId');
      return;
    }

    // Corporate booking. Corporate-enrolled users (or anyone who has already
    // supplied company details) pass straight through.
    final profile = ref.read(userProfileProvider).valueOrNull;
    final hasCompanyDetails = profile?.corporate?.name.isNotEmpty ?? false;
    final isCorporateAccount = profile?.accountType == AccountType.corporate;
    if (isCorporateAccount || hasCompanyDetails) {
      context.push('${AppRoutes.bookingCorporate}?listingId=$listingId');
      return;
    }

    // Individual customer going corporate -> collect company name, GSTIN, etc.
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final saved = await CompanyDetailsSheet.show(
      context,
      managerName: profile?.individual?.fullName ?? profile?.displayName ?? '',
      managerPhone: profile?.individual?.mobile ?? profile?.phone ?? '',
      initialEmail: profile?.email ?? '',
      onSubmit: (data) => ref
          .read(userProfileRepositoryProvider)
          .saveCorporateOrg(user.id, data),
    );
    if (saved == true && mounted) {
      context.push('${AppRoutes.bookingCorporate}?listingId=$listingId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingProvider);
    final selected = draft.bookingType ?? AccountType.corporate;

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const BookingTopBar(currentStep: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SelectedBoardCard(listing: widget.listing),
                    const SizedBox(height: AppSpacing.xxxl),
                    Text(
                      'How is this ',
                      style: AppTextStyles.brandHuge.copyWith(
                        fontSize: 30,
                        color: context.colors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.brandHugeItalic.copyWith(
                          fontSize: 30,
                          color: AppColors.primary,
                          height: 1.2,
                        ),
                        children: const [
                          TextSpan(text: 'ad placed?'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Pick the account paying for this campaign. '
                      'Determines verification & invoicing.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: context.colors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeCard(
                            icon: Icons.business_center_outlined,
                            title: 'Corporate',
                            subtitle: 'Brand campaign',
                            selected: selected == AccountType.corporate,
                            onTap: () => ref
                                .read(bookingProvider.notifier)
                                .setType(AccountType.corporate),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _TypeCard(
                            icon: Icons.person_outline_rounded,
                            title: 'Individual',
                            subtitle: 'Personal moment',
                            selected: selected == AccountType.individual,
                            onTap: () => ref
                                .read(bookingProvider.notifier)
                                .setType(AccountType.individual),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.lg,
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
                        'Continue as ${selected.displayLabel}',
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

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
          innerColor: selected ? context.colors.surface : context.colors.card,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : context.colors.surface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: AppColors.primaryDark, size: 22),
                  ),
                  const Spacer(),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : context.colors.textTertiary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: AppTextStyles.brandHuge.copyWith(
                  fontSize: 18,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
