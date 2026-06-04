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
import '../../../../app/theme/app_palette.dart';

/// Soft-pink failure screen shown when payment fails. The booking slot is
/// held for 15 minutes so the user can retry.
class PaymentFailureScreen extends ConsumerStatefulWidget {
  const PaymentFailureScreen({super.key});

  @override
  ConsumerState<PaymentFailureScreen> createState() =>
      _PaymentFailureScreenState();
}

class _PaymentFailureScreenState
    extends ConsumerState<PaymentFailureScreen> {
  static const _bg = Color(0xFFF7DEE6);
  static const _accent = Color(0xFFB7245B);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: _bg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _tryAgain() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.bookingReview);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.huge),

              Center(
                child: CustomPaint(
                  painter: _DashedRingPainter(),
                  child: const SizedBox(
                    width: 130,
                    height: 130,
                    child: Center(
                      child: _StatusCircle(
                        color: _accent,
                        icon: Icons.close_rounded,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Title — "Payment" + " didn't go through."
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.brandHuge.copyWith(
                    fontSize: 32,
                    color: const Color(0xFF1A1A22),
                    height: 1.2,
                  ),
                  children: [
                    const TextSpan(text: 'Payment '),
                    TextSpan(
                      text: "didn't\ngo through.",
                      style: AppTextStyles.brandHugeItalic.copyWith(
                        fontSize: 32,
                        color: _accent,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                "Don't worry — your booking is held. You can try again in a moment.",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: const Color(0xFF5E5E68),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Reason card
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: const Border(
                    left: BorderSide(color: _accent, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REASON',
                      style: AppTextStyles.brandFooter.copyWith(
                        color: _accent,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Insufficient funds in the linked UPI account. '
                      'No amount was deducted.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFF1A1A22),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'CODE: E_INSUFFICIENT_BAL  ·  14:23 IST',
                      style: AppTextStyles.brandFooter.copyWith(
                        color: const Color(0xFF9494A0),
                        fontFamily: 'monospace',
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Slot reserved info
              GradientBorderBox(
                borderRadius: AppSpacing.radiusMd,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE4FA),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your slot is reserved for 15 minutes',
                            style: AppTextStyles.brandHuge.copyWith(
                              fontSize: 15,
                              color: const Color(0xFF1A1A22),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Try a different payment method or top up '
                            'your account and retry.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFF5E5E68),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Try again CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _tryAgain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Try again',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Change payment method (outlined)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _tryAgain,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A22),
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.18),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  child: Text(
                    'Change payment method',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: const Color(0xFF1A1A22),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Support link
              GestureDetector(
                onTap: () => context.showSnack('Support (Phase 1b)'),
                child: Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'NEED HELP?  ',
                        style: AppTextStyles.brandFooter.copyWith(
                          color: const Color(0xFF9494A0),
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'CONTACT SUPPORT',
                        style: AppTextStyles.brandFooter.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCircle extends StatelessWidget {
  const _StatusCircle({required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: 40),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.black.withValues(alpha: 0.25);
    final radius = size.width / 2 - 4;
    const dashArc = 0.05;
    const gapArc = 0.04;
    var start = 0.0;
    while (start < 6.28318) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: radius,
        ),
        start,
        dashArc,
        false,
        paint,
      );
      start += dashArc + gapArc;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
