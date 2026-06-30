import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../user/presentation/providers/user_profile_provider.dart';
import '../../data/invoice_builder.dart';
import '../../domain/booking_totals.dart';
import '../providers/booking_provider.dart';
import '../../../../app/theme/app_palette.dart';

/// Light-green confirmation screen shown after a successful payment.
class PaymentSuccessScreen extends ConsumerStatefulWidget {
  const PaymentSuccessScreen({super.key});

  @override
  ConsumerState<PaymentSuccessScreen> createState() =>
      _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState
    extends ConsumerState<PaymentSuccessScreen> {
  // Soft-green palette specific to this screen.
  static const _bg = Color(0xFFE7F0CF);
  static const _accent = Color(0xFF6E8E1F);

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

  void _trackInHistory() {
    ref.read(bookingProvider.notifier).reset();
    context.go(AppRoutes.history);
  }

  /// Builds the invoice PDF in-memory and shows the OS share/save sheet
  /// so the user can AirDrop, email, or save to Files / Drive. Works on
  /// both iOS and Android.
  Future<void> _downloadInvoice({
    required String orderRef,
    required int amount,
    required int duration,
  }) async {
    final draft = ref.read(bookingProvider);
    final listing = draft.listing;
    if (listing == null) {
      context.showSnack('Booking details unavailable.');
      return;
    }
    final totals = BookingTotals.compute(
      dailyRate: listing.pricePerDay,
      durationDays: duration,
    );
    final profile = ref.read(userProfileProvider).asData?.value;

    final data = InvoiceData(
      orderRef: orderRef,
      campaignTitle: (draft.campaignTitle?.isNotEmpty == true)
          ? draft.campaignTitle!
          : 'Untitled campaign',
      boardLabel: listing.boardType,
      location: listing.location,
      durationDays: duration,
      dailyRate: listing.pricePerDay,
      subtotal: totals.subtotal - totals.discount,
      gst: totals.gst,
      total: totals.total,
      status: 'Admin review',
      customerName: profile?.bestDisplayName,
      customerEmail:
          profile?.email ?? profile?.corporate?.officialEmail,
      customerPhone:
          profile?.phone ?? profile?.individual?.mobile,
    );

    try {
      // Build the PDF in memory, then write it to a temp file so we can
      // hand its path to share_plus. The OS share sheet opens with the
      // PDF already attached — same UX as the printing package, no native
      // CocoaPods dependency required.
      final bytes = await InvoiceBuilder.build(data);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/NammaSign_invoice_$orderRef.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'NammaSign invoice — $orderRef',
        text: 'Tax invoice for your NammaSign booking $orderRef.',
      );
      await ref.read(analyticsServiceProvider).invoiceDownloaded();
    } catch (e) {
      if (!mounted) return;
      context.showSnack("Couldn't generate invoice. Please try again.");
    }
  }

  /// Opens the OS share sheet with a short plain-text summary of the
  /// booking. Lighter-weight than the PDF — good for forwarding the
  /// order reference via WhatsApp / SMS / etc.
  Future<void> _shareBooking({
    required String orderRef,
    required int amount,
    required int duration,
  }) async {
    final draft = ref.read(bookingProvider);
    final listing = draft.listing;
    final title = draft.campaignTitle;
    final lines = <String>[
      'NammaSign booking confirmed',
      '',
      'Order ref: $orderRef',
      if (title != null && title.isNotEmpty) 'Campaign: $title',
      if (listing != null) 'Board: ${listing.location} · ${listing.boardType}',
      'Duration: $duration day${duration == 1 ? '' : 's'}',
      'Total: Rs $amount (incl. 18% GST)',
      '',
      'Track it in the NammaSign app — History tab.',
    ];
    try {
      await Share.share(
        lines.join('\n'),
        subject: 'NammaSign booking — $orderRef',
      );
      await ref.read(analyticsServiceProvider).appBookingShared();
    } catch (e) {
      if (!mounted) return;
      context.showSnack("Couldn't open share sheet.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingProvider);
    final listing = draft.listing;
    final duration = draft.durationDays ?? 15;
    final amount = listing == null
        ? 0
        : BookingTotals.compute(
            dailyRate: listing.pricePerDay,
            durationDays: duration,
          ).total;
    final orderRef = 'NE-2026-A${(amount * 7 % 9000 + 1000).round()}';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.huge),

              // Dashed ring with green check
              Center(
                child: CustomPaint(
                  painter: _DashedRingPainter(),
                  child: const SizedBox(
                    width: 130,
                    height: 130,
                    child: Center(
                      child: _StatusCircle(
                        color: _accent,
                        icon: Icons.check_rounded,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'Booking',
                textAlign: TextAlign.center,
                style: AppTextStyles.brandHuge.copyWith(
                  fontSize: 32,
                  color: const Color(0xFF1A1A22),
                  height: 1.2,
                ),
              ),
              Text(
                'submitted.',
                textAlign: TextAlign.center,
                style: AppTextStyles.brandHugeItalic.copyWith(
                  fontSize: 32,
                  color: _accent,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Your campaign is now in admin review. Our team will reach '
                'out about payment and confirm it goes live.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: const Color(0xFF5E5E68),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Order reference card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'ORDER REFERENCE',
                      style: AppTextStyles.brandFooter.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      orderRef,
                      style: AppTextStyles.brandHuge.copyWith(
                        fontSize: 20,
                        color: const Color(0xFF1A1A22),
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Line(
                      label: 'Campaign',
                      value: draft.campaignTitle ??
                          draft.purpose ??
                          'Untitled campaign',
                    ),
                    _Line(
                      label: 'Board',
                      value: '${listing?.location ?? "—"} · '
                          '${listing?.boardType ?? "—"}',
                    ),
                    _Line(
                      label: 'Duration',
                      value: '$duration ${duration == 1 ? "day" : "days"}',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DashedLine(color: AppColors.primary.withValues(alpha: 0.2)),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AMOUNT DUE',
                              style: AppTextStyles.brandFooter.copyWith(
                                color: const Color(0xFF9494A0),
                                letterSpacing: 2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${formatRupees(amount)}',
                              style: AppTextStyles.brandHuge.copyWith(
                                fontSize: 22,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ADMIN REVIEW',
                          style: AppTextStyles.brandFooter.copyWith(
                            color: AppColors.warning,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _SecondaryButton(
                      icon: Icons.download_rounded,
                      label: 'Download\ninvoice',
                      onTap: () => _downloadInvoice(
                        orderRef: orderRef,
                        amount: amount,
                        duration: duration,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _SecondaryButton(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: () => _shareBooking(
                        orderRef: orderRef,
                        amount: amount,
                        duration: duration,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _trackInHistory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.badgeDark,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  child: Text(
                    'Track in History',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
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

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF5E5E68),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF1A1A22),
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _LinePainter(color: color),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
      x += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF1A1A22), size: 16),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label.replaceAll('\n', ' '),
                style: AppTextStyles.brandHuge.copyWith(
                  fontSize: 13,
                  color: const Color(0xFF1A1A22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
