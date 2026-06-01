import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../features/history/domain/booking.dart';
import '../../../../features/home/domain/billboard_listing.dart';
import '../../../../features/home/presentation/providers/listings_provider.dart';
import '../../../app/admin_routes.dart';
import '../../../shared/theme/admin_theme.dart';
import '../../../shared/widgets/admin_shell.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../widgets/add_area_dialog.dart';

class AreasListScreen extends ConsumerWidget {
  const AreasListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(listingsStreamProvider);
    final bookings = ref.watch(adminAllBookingsProvider);
    return AdminShell(
      section: AdminSection.areas,
      title: 'Areas',
      subtitle: 'Boards available for booking',
      actions: [
        FilledButton.icon(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const AddAreaDialog(),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add area'),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AdminSpacing.xxl),
        child: listings.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text("Couldn't load areas\n$e"),
          data: (areas) {
            if (areas.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text('No areas configured.', style: AdminText.bodyMedium),
                ),
              );
            }
            final bookingList = bookings.asData?.value ?? const [];
            return LayoutBuilder(builder: (ctx, c) {
              final isWide = c.maxWidth > 1000;
              return GridView.count(
                crossAxisCount: isWide ? 3 : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AdminSpacing.md,
                crossAxisSpacing: AdminSpacing.md,
                childAspectRatio: isWide ? 1.6 : 2.4,
                children: [
                  for (final a in areas)
                    _AreaCard(
                      area: a,
                      bookings: bookingList
                          .where((b) => b.areaId == a.id)
                          .toList(),
                    ),
                ],
              );
            });
          },
        ),
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.area, required this.bookings});
  final BillboardListing area;
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final activeCount =
        bookings.where((b) => b.status == BookingStatus.live).length;
    final pendingCount = bookings
        .where((b) => b.status == BookingStatus.pending)
        .length;
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AdminColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AdminColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.location,
                      style: AdminText.h1.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(area.boardType, style: AdminText.bodySmall),
                  ],
                ),
              ),
              _StatusPill(area: area),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(
                label: '₹/DAY',
                value:
                    '₹${NumberFormat.decimalPattern('en_IN').format(area.pricePerDay)}',
              ),
              _Stat(label: 'BOARDS', value: '${area.boardCount}'),
              _Stat(label: 'LIVE', value: '$activeCount'),
              _Stat(label: 'PENDING', value: '$pendingCount'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AdminText.label),
        Text(label, style: AdminText.bodySmall),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.area});
  final BillboardListing area;

  @override
  Widget build(BuildContext context) {
    final isActive = area.availability == AvailabilityStatus.available;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AdminColors.successBg : AdminColors.warningBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'AVAILABLE' : 'LIMITED',
        style: TextStyle(
          color: isActive ? AdminColors.success : AdminColors.warning,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
