import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/billboard_listing.dart';
import '../providers/listings_provider.dart';
import 'billboard_card.dart';
import '../../../../app/theme/app_palette.dart';

/// Local tab body — live search bar + filtered list of [BillboardCard]s.
///
/// The listings stream still comes from Firestore. Filtering happens
/// client-side against location / full address / id so the user can type
/// "kora" and immediately see Koramangala. When the query matches nothing
/// we show an empty-state placeholder.
class LocalTab extends ConsumerStatefulWidget {
  const LocalTab({super.key});

  @override
  ConsumerState<LocalTab> createState() => _LocalTabState();
}

class _LocalTabState extends ConsumerState<LocalTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    setState(() => _query = v.trim().toLowerCase());
  }

  /// Matches the typed query against location, full address, and id.
  bool _matches(BillboardListing l) {
    if (_query.isEmpty) return true;
    return l.location.toLowerCase().contains(_query) ||
        l.fullAddress.toLowerCase().contains(_query) ||
        l.id.toLowerCase().contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsStreamProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        // Slightly wider side gutters than the design system default so
        // the area cards have breathing room against the screen edges.
        AppSpacing.xxl + 8,
        AppSpacing.lg,
        AppSpacing.xxl + 8,
        AppSpacing.xxxl,
      ),
      children: [
        _SearchBar(
          controller: _searchCtrl,
          onChanged: _onQueryChanged,
          onClear: () {
            _searchCtrl.clear();
            _onQueryChanged('');
          },
        ),
        const SizedBox(height: AppSpacing.xxl),
        listingsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.huge),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.huge,
              horizontal: AppSpacing.lg,
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 32,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    "Couldn't load listings",
                    style: AppTextStyles.h3.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (listings) {
            if (listings.isEmpty) {
              return const _EmptyState(
                icon: Icons.storefront_outlined,
                title: 'No active locations yet',
                subtitle: 'Check back soon — new boards are added weekly.',
              );
            }
            final filtered = listings.where(_matches).toList();
            if (filtered.isEmpty) {
              return _EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No areas match "${_searchCtrl.text}"',
                subtitle:
                    "We don't have boards in that area yet. Try Koramangala, "
                    'Madiwala, or Electronic City.',
              );
            }
            return Column(
              children: [
                for (final l in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: BillboardCard(
                      listing: l,
                      onTap: () => context.push(
                        '${AppRoutes.bookingSelectType}?listingId=${l.id}',
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: context.colors.textTertiary,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            // The app's global dark inputDecorationTheme has filled=true with
            // a near-black fillColor. Without overriding both here, the
            // TextField paints a black rectangle under the typed text and the
            // characters become unreadable. Forcing filled:false and a
            // transparent fillColor lets the white container background
            // show through.
            child: Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: AppColors.primary,
                  selectionColor: AppColors.primary.withValues(alpha: 0.25),
                  selectionHandleColor: AppColors.primary,
                ),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                cursorColor: AppColors.primary,
                textInputAction: TextInputAction.search,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: context.colors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by area or board ID...',
                  hintStyle: AppTextStyles.bodyLarge.copyWith(
                    color: context.colors.textTertiary,
                  ),
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  isCollapsed: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.only(left: AppSpacing.sm),
                child: Icon(
                  Icons.close_rounded,
                  color: context.colors.textTertiary,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Generic empty-state placeholder shown when listings are empty or the
/// search query has no matches.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.huge,
        horizontal: AppSpacing.lg,
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.h3.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.colors.textTertiary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
