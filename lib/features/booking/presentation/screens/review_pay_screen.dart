import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/booking_totals.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_top_bar.dart';
import '../widgets/order_summary_card.dart';
import '../widgets/payment_method_card.dart';

/// Step 3 — order summary + payment method selection.
///
/// Tap "Pay" → success page.
/// Long-press "Pay" → failure page (demo affordance so both screens are
/// reachable without backend integration; in Phase 1b real Razorpay status
/// determines branch).
class ReviewPayScreen extends ConsumerStatefulWidget {
  const ReviewPayScreen({super.key});

  @override
  ConsumerState<ReviewPayScreen> createState() => _ReviewPayScreenState();
}

class _ReviewPayScreenState extends ConsumerState<ReviewPayScreen> {
  PaymentMethod _method = PaymentMethod.upi;
  bool _processing = false;

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

  Future<void> _pay({required bool simulateFailure}) async {
    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _processing = false);
    context.push(
      simulateFailure ? AppRoutes.bookingFailure : AppRoutes.bookingSuccess,
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingProvider);
    final listing = draft.listing;

    if (listing == null) {
      // Defensive — shouldn't happen because users get here through the
      // flow, but if they deep-link in, send them home.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRoutes.home);
      });
      return const Scaffold();
    }

    final durationDays = draft.durationDays ?? 15;
    final totals = BookingTotals.compute(
      dailyRate: listing.pricePerDay,
      durationDays: durationDays,
    );
    final campaignTitle = draft.campaignTitle?.isNotEmpty == true
        ? draft.campaignTitle!
        : (draft.purpose ?? 'Untitled campaign');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            const BookingTopBar(currentStep: 3),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.md,
                  AppSpacing.xxl,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Review & ',
                      style: AppTextStyles.brandHuge.copyWith(
                        fontSize: 30,
                        color: AppColors.textPrimaryOnLight,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'pay.',
                      style: AppTextStyles.brandHugeItalic.copyWith(
                        fontSize: 30,
                        color: AppColors.primary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      "Verify everything below. You'll be charged after "
                      'admin approval.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondaryOnLight,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    OrderSummaryCard(
                      listing: listing,
                      campaignTitle: campaignTitle,
                      durationDays: durationDays,
                      totals: totals,
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text(
                        'PAYMENT METHOD',
                        style: AppTextStyles.brandFooter.copyWith(
                          color: AppColors.textTertiaryOnLight,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    PaymentMethodCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'UPI · GPay',
                      subtitle: 'priya@oksbi',
                      selected: _method == PaymentMethod.upi,
                      onTap: () =>
                          setState(() => _method = PaymentMethod.upi),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PaymentMethodCard(
                      icon: Icons.credit_card_rounded,
                      title: 'Card · HDFC ·· 4821',
                      subtitle: 'VISA · EXP 11/27',
                      selected: _method == PaymentMethod.card,
                      onTap: () =>
                          setState(() => _method = PaymentMethod.card),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PaymentMethodCard(
                      icon: Icons.account_balance_outlined,
                      title: 'Net banking',
                      subtitle: 'All major banks',
                      selected: _method == PaymentMethod.netbanking,
                      onTap: () =>
                          setState(() => _method = PaymentMethod.netbanking),
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                0,
                AppSpacing.xxl,
                AppSpacing.md,
              ),
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onLongPress: _processing
                      ? null
                      : () => _pay(simulateFailure: true),
                  child: ElevatedButton(
                    onPressed: _processing
                        ? null
                        : () => _pay(simulateFailure: false),
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
                    child: _processing
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Pay ₹${formatRupees(totals.total)} securely',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const Icon(
                                Icons.lock_outline_rounded,
                                size: 18,
                                color: AppColors.textPrimary,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 11,
                    color: AppColors.textTertiaryOnLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '256-bit encryption  ·  Powered by Razorpay',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiaryOnLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
