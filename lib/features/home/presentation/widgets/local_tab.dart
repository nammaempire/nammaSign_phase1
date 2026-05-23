import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/billboard_listing.dart';
import 'billboard_card.dart';

/// Local tab body — plain search bar (no location chip per request) +
/// scrollable list of [BillboardCard]s. Filter chips removed per request.
class LocalTab extends StatelessWidget {
  const LocalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ),
      children: [
        const _SearchBar(),
        const SizedBox(height: AppSpacing.xxl),
        ...sampleListings.map(
          (l) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: BillboardCard(
              listing: l,
              onTap: () => context.push(
                '${AppRoutes.bookingSelectType}?listingId=${l.id}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.textTertiaryOnLight,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Search by area or board ID...',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textTertiaryOnLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
