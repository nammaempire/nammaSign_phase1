import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/billboard_listing.dart';

/// Single billboard listing card on the Local tab.
///
/// Dark purple gradient hero with a billboard illustration inside, an
/// availability pill top-right, a price chip bottom-left, and a white
/// title strip below.
class BillboardCard extends StatelessWidget {
  const BillboardCard({super.key, required this.listing, this.onTap});

  final BillboardListing listing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero section
                Container(
                  height: 220,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryDark,
                        Color(0xFF2A1056),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Billboard illustration centered
                      Center(
                        child: _CardBillboard(label: listing.displayLabel),
                      ),

                      // Status pill (top-right)
                      Positioned(
                        top: AppSpacing.md,
                        right: AppSpacing.md,
                        child: _StatusPill(
                          status: listing.availability,
                          slotsLeft: listing.slotsLeft,
                        ),
                      ),

                      // Price chip (bottom-left)
                      Positioned(
                        bottom: AppSpacing.md,
                        left: AppSpacing.md,
                        child: _PricePill(price: listing.pricePerDay),
                      ),
                    ],
                  ),
                ),

                // Footer — title, address, views, CTA
                _CardFooter(listing: listing, onBook: onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mini billboard inside a card — purple-bordered dark screen with the
/// listing label and a 12,000 VIEWS/DAY footer, sitting on two support legs.
class _CardBillboard extends StatelessWidget {
  const _CardBillboard({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 160,
      child: Stack(
        children: [
          // Screen
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary,
                  width: 2.5,
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.brandHuge.copyWith(
                      fontSize: 28,
                      color: AppColors.secondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '12,000 VIEWS/DAY',
                    style: AppTextStyles.brandFooter.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.7),
                      letterSpacing: 1.5,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Left leg
          Positioned(
            top: 110,
            left: 70,
            child: Container(
              width: 4,
              height: 40,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          // Right leg
          Positioned(
            top: 110,
            right: 70,
            child: Container(
              width: 4,
              height: 40,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// "● AVAILABLE" (green dot, white pill) / "● 2 LEFT" (amber dot, white pill)
/// / "FULLY BOOKED" (red).
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.slotsLeft});

  final AvailabilityStatus status;
  final int slotsLeft;

  @override
  Widget build(BuildContext context) {
    final (label, dotColor, textColor) = switch (status) {
      AvailabilityStatus.available => (
        'AVAILABLE',
        AppColors.success,
        AppColors.success,
      ),
      AvailabilityStatus.fewLeft => (
        '$slotsLeft LEFT',
        AppColors.warning,
        AppColors.warning,
      ),
      AvailabilityStatus.fullyBooked => (
        'FULLY BOOKED',
        AppColors.error,
        AppColors.error,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.brandFooter.copyWith(
              color: textColor,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// "₹450 /day" dark chip.
class _PricePill extends StatelessWidget {
  const _PricePill({required this.price});
  final int price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.badgeDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '₹$price',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            ' /day',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// White footer below the hero — title, multi-line address, person+views
/// row, and the "Book my slot" CTA (disabled when fully booked).
class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.listing, required this.onBook});

  final BillboardListing listing;
  final VoidCallback? onBook;

  static String _formatViews(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final fullyBooked = listing.availability == AvailabilityStatus.fullyBooked;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            '${listing.location}  ·  ${listing.boardType}',
            style: AppTextStyles.brandHuge.copyWith(
              fontSize: 18,
              color: AppColors.textPrimaryOnLight,
              height: 1.2,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Full address — two lines
          Text(
            listing.fullAddress,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryOnLight,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppSpacing.sm + 2),

          // Person icon + views/day
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: AppColors.textSecondaryOnLight,
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatViews(listing.viewsPerDay)} views/day',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryOnLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // CTA
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: fullyBooked ? null : onBook,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.18),
                disabledForegroundColor:
                    AppColors.textPrimaryOnLight.withValues(alpha: 0.55),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    fullyBooked ? 'Fully booked' : 'Book my slot',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: fullyBooked
                          ? AppColors.textTertiaryOnLight
                          : AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  if (!fullyBooked) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
