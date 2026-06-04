import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/booking.dart';
import '../providers/bookings_provider.dart';
import '../widgets/booking_card.dart';
import '../widgets/status_filter_chip.dart';
import '../../../../app/theme/app_palette.dart';

/// History tab — live list of the signed-in user's bookings, with
/// status filter chips along the top.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  /// null = "All". Otherwise filter to a specific status.
  BookingStatus? _filter;

  @override
  void initState() {
    super.initState();
  }

  List<Booking> _applyFilter(List<Booking> all) {
    if (_filter == null) return all;
    return all.where((b) => b.status == _filter).toList();
  }

  int _countOf(List<Booking> all, BookingStatus? s) {
    if (s == null) return all.length;
    return all.where((b) => b.status == s).length;
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(userBookingsStreamProvider);

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your ',
                    style: AppTextStyles.brandHuge.copyWith(
                      fontSize: 28,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  Text(
                    'history',
                    style: AppTextStyles.brandHugeItalic.copyWith(
                      fontSize: 28,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: bookingsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 32,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          "Couldn't load your history",
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
                data: (all) {
                  final filtered = _applyFilter(all);
                  return Column(
                    children: [
                      // Filter chips (need access to `all` for counts)
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxl,
                          ),
                          children: [
                            StatusFilterChip(
                              label: 'All',
                              count: _countOf(all, null),
                              active: _filter == null,
                              onTap: () => setState(() => _filter = null),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            StatusFilterChip(
                              label: 'Pending',
                              count: _countOf(all, BookingStatus.pending),
                              active: _filter == BookingStatus.pending,
                              onTap: () => setState(
                                  () => _filter = BookingStatus.pending),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            StatusFilterChip(
                              label: 'Live',
                              count: _countOf(all, BookingStatus.live),
                              active: _filter == BookingStatus.live,
                              onTap: () => setState(
                                  () => _filter = BookingStatus.live),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            StatusFilterChip(
                              label: 'Rejected',
                              count: _countOf(all, BookingStatus.rejected),
                              active: _filter == BookingStatus.rejected,
                              onTap: () => setState(
                                  () => _filter = BookingStatus.rejected),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      AppSpacing.xxl),
                                  child: Text(
                                    all.isEmpty
                                        ? 'No bookings yet.\n'
                                            'Book your first slot from Home.'
                                        : 'No bookings in this category.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: context.colors.textTertiary,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.xxl,
                                  AppSpacing.sm,
                                  AppSpacing.xxl,
                                  AppSpacing.xxxl,
                                ),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSpacing.md),
                                itemBuilder: (_, i) => BookingCard(
                                  booking: filtered[i],
                                  onTap: () => context.push(
                                    AppRoutes
                                        .campaignStatusFor(filtered[i].id),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
