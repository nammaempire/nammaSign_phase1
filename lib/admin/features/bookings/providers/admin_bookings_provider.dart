import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/history/domain/booking.dart';
import '../../../../features/history/presentation/providers/bookings_provider.dart';

/// Live admin queue: every booking currently in `pending_review`, oldest first.
final pendingBookingsStreamProvider =
    StreamProvider<List<Booking>>((ref) {
  final repo = ref.watch(bookingsRepositoryProvider);
  return repo.adminWatchByStatus(BookingStatus.pending.storageValue);
});
