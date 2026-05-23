import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../home/domain/billboard_listing.dart';

/// Compact summary card shown above step 1 — tells the user which billboard
/// they're booking.
class SelectedBoardCard extends StatelessWidget {
  const SelectedBoardCard({super.key, required this.listing});

  final BillboardListing listing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, Color(0xFF2A1056)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.desktop_windows_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELECTED BOARD',
                  style: AppTextStyles.brandFooter.copyWith(
                    color: AppColors.primaryAccent,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${listing.location} · ${listing.boardType}',
                  style: AppTextStyles.brandHuge.copyWith(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _firstLine(listing.fullAddress),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹${listing.pricePerDay}',
                      style: AppTextStyles.brandHuge.copyWith(
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      ' / day',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _firstLine(String s) => s.split('\n').first;
}
