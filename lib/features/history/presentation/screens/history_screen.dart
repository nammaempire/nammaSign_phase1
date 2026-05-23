import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/booking.dart';
import '../widgets/booking_card.dart';
import '../widgets/status_filter_chip.dart';

/// History tab — list of all bookings the user has placed, with status
/// filter chips along the top.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // null = "All". Otherwise filter to a specific status.
  BookingStatus? _filter;

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

  List<Booking> get _visible {
    if (_filter == null) return sampleBookings;
    return sampleBookings.where((b) => b.status == _filter).toList();
  }

  int _countOf(BookingStatus? s) {
    if (s == null) return sampleBookings.length;
    return sampleBookings.where((b) => b.status == s).length;
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _visible;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title + search
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Your ',
                          style: AppTextStyles.brandHuge.copyWith(
                            fontSize: 28,
                            color: AppColors.textPrimaryOnLight,
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
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          context.showSnack('Search history (Phase 1b)'),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.search_rounded,
                          color: AppColors.textPrimaryOnLight,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter chips
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
                    count: _countOf(null),
                    active: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  StatusFilterChip(
                    label: 'Pending',
                    count: _countOf(BookingStatus.pending),
                    active: _filter == BookingStatus.pending,
                    onTap: () =>
                        setState(() => _filter = BookingStatus.pending),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  StatusFilterChip(
                    label: 'Live',
                    count: _countOf(BookingStatus.live),
                    active: _filter == BookingStatus.live,
                    onTap: () =>
                        setState(() => _filter = BookingStatus.live),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  StatusFilterChip(
                    label: 'Rejected',
                    count: _countOf(BookingStatus.rejected),
                    active: _filter == BookingStatus.rejected,
                    onTap: () =>
                        setState(() => _filter = BookingStatus.rejected),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // List of bookings
            Expanded(
              child: bookings.isEmpty
                  ? Center(
                      child: Text(
                        'No bookings in this category.',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textTertiaryOnLight,
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
                      itemCount: bookings.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (_, i) => BookingCard(
                        booking: bookings[i],
                        onTap: () => context.push(
                          AppRoutes.campaignStatusFor(bookings[i].id),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
