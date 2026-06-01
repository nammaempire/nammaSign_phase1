import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_border_box.dart';
import '../../../home/domain/billboard_listing.dart';
import '../../domain/booking_totals.dart';

/// White summary card for the review/pay screen. Shows the selected board
/// header, a list of charge line items, and the final purple total.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    super.key,
    required this.listing,
    required this.campaignTitle,
    required this.durationDays,
    required this.totals,
  });

  final BillboardListing listing;
  final String campaignTitle;
  final int durationDays;
  final BookingTotals totals;

  @override
  Widget build(BuildContext context) {
    return GradientBorderBox(
      borderRadius: AppSpacing.radiusLg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.desktop_windows_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${listing.location} · ${listing.boardType}',
                      style: AppTextStyles.brandHuge.copyWith(
                        fontSize: 16,
                        color: AppColors.textPrimaryOnLight,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _shortLocation(listing.fullAddress).toUpperCase(),
                      style: AppTextStyles.brandFooter.copyWith(
                        color: AppColors.textTertiaryOnLight,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const _DashedDivider(),
          const SizedBox(height: AppSpacing.md),

          // Line items
          _Line(label: 'Campaign', value: campaignTitle, valueStrong: true),
          _Line(
            label: 'Duration',
            value: durationDays == 1 ? '1 day' : '$durationDays days',
            valueStrong: true,
          ),
          _Line(
            label: 'Daily rate',
            value: '₹${formatRupees(listing.pricePerDay)}',
            valueStrong: true,
          ),
          _Line(
            label: 'Subtotal',
            value: '₹${formatRupees(totals.subtotal)}',
            muted: true,
          ),
          if (totals.discount > 0)
            _Line(
              label: 'Multi-day discount',
              value: '−₹${formatRupees(totals.discount)}',
              valueColor: AppColors.success,
            ),
          _Line(
            label: 'GST (18%)',
            value: '₹${formatRupees(totals.gst)}',
            muted: true,
          ),

          const SizedBox(height: AppSpacing.md),
          const _DashedDivider(),
          const SizedBox(height: AppSpacing.md),

          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyles.brandHuge.copyWith(
                  fontSize: 22,
                  color: AppColors.textPrimaryOnLight,
                ),
              ),
              Text(
                '₹${formatRupees(totals.total)}',
                style: AppTextStyles.brandHuge.copyWith(
                  fontSize: 24,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Pulls just the city/area portion from the first address line for the
  /// uppercase mini-subtitle ("INDIRANAGAR · BLR").
  String _shortLocation(String fullAddress) {
    final first = fullAddress.split('\n').first;
    // Best-effort: last comma-separated chunk is usually the area.
    final parts = first.split(',').map((s) => s.trim()).toList();
    if (parts.length >= 2) {
      return '${parts[parts.length - 1]}  ·  BLR';
    }
    return 'BLR';
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.valueStrong = false,
    this.muted = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool valueStrong;
  final bool muted;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: muted
                  ? AppColors.textTertiaryOnLight
                  : AppColors.textSecondaryOnLight,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Value flexes — long campaign titles wrap to the next line
          // instead of pushing past the card edge.
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium.copyWith(
                color: valueColor ??
                    (muted
                        ? AppColors.textTertiaryOnLight
                        : AppColors.textPrimaryOnLight),
                fontWeight: valueStrong ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedLinePainter(),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    const dashWidth = 4.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
