import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../user/presentation/providers/user_profile_provider.dart';
import '../../data/razorpay_service.dart';
import '../../domain/booking_totals.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_top_bar.dart';
import '../widgets/order_summary_card.dart';
import '../widgets/payment_method_card.dart';
import '../../../../app/theme/app_palette.dart';

/// Step 3 — order summary + payment.
///
/// Tapping "Pay" creates the booking as `pending_payment`, opens the
/// Razorpay Checkout sheet, and — once the payment is verified server-side —
/// routes to the success page. A failed/declined payment routes to the
/// failure page; the booking stays `pending_payment` so it can be retried.
class ReviewPayScreen extends ConsumerStatefulWidget {
  const ReviewPayScreen({super.key});

  @override
  ConsumerState<ReviewPayScreen> createState() => _ReviewPayScreenState();
}

class _ReviewPayScreenState extends ConsumerState<ReviewPayScreen> {
  PaymentMethod _method = PaymentMethod.upi;
  bool _processing = false;

  // The booking is created once (as pending_payment). If the first payment
  // is cancelled/declined and the user taps Pay again, we reuse this id so we
  // don't create a duplicate booking each retry.
  String? _bookingId;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _submit() async {
    setState(() => _processing = true);

    // Prefill Razorpay Checkout from the signed-in user's profile.
    final profile = ref.read(userProfileProvider).asData?.value;

    // Create the booking only once; reuse it on retry.
    if (_bookingId == null) {
      try {
        _bookingId = await ref
            .read(bookingProvider.notifier)
            .submit(paymentMethod: _method.label);
      } catch (e) {
        if (!mounted) return;
        setState(() => _processing = false);
        context.showErrorSnack('Could not submit booking. Please try again.');
        return;
      }
    }

    final result =
        await ref.read(razorpayPaymentServiceProvider).payForBooking(
              bookingId: _bookingId!,
              displayName: profile?.bestDisplayName,
              email: profile?.email ?? profile?.corporate?.officialEmail,
              contact: profile?.phone ?? profile?.individual?.mobile,
            );

    if (!mounted) return;
    setState(() => _processing = false);

    if (result.success) {
      context.push(AppRoutes.bookingSuccess);
    } else if (result.cancelled) {
      // User dismissed the sheet — stay on this screen so they can retry.
      // The booking is saved as "awaiting payment" and also appears in History.
      context.showSnack(
        'Payment cancelled. You can pay again — it\'s saved under History.',
      );
    } else {
      context.push(AppRoutes.bookingFailure);
    }
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
      backgroundColor: context.colors.bg,
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
                        color: context.colors.textPrimary,
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
                      'Verify everything below, then pay securely to send '
                      'your campaign for review.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: context.colors.textSecondary,
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
                          color: context.colors.textTertiary,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    PaymentMethodCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'UPI',
                      subtitle: 'Pay using any UPI app',
                      selected: _method == PaymentMethod.upi,
                      onTap: () =>
                          setState(() => _method = PaymentMethod.upi),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PaymentMethodCard(
                      icon: Icons.credit_card_rounded,
                      title: 'Card',
                      subtitle: 'Visa, Mastercard, RuPay',
                      selected: _method == PaymentMethod.card,
                      onTap: () =>
                          setState(() => _method = PaymentMethod.card),
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
                child: ElevatedButton(
                    onPressed: _processing ? null : _submit,
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
                                'Pay ₹${formatRupees(totals.total)}',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const Icon(
                                Icons.lock_rounded,
                                size: 17,
                                color: AppColors.textPrimary,
                              ),
                            ],
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
                    Icons.verified_user_outlined,
                    size: 11,
                    color: context.colors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Secured by Razorpay  ·  UPI, cards & netbanking',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.colors.textTertiary,
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
