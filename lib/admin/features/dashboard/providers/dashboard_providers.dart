import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/history/domain/booking.dart';
import '../../../../features/history/presentation/providers/bookings_provider.dart';
import '../../../../features/user/domain/user_profile.dart';
import '../../../../shared/providers/firebase_providers.dart';

/// Admin-only: live stream of every booking in the system.
final adminAllBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('bookings')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Booking.fromFirestore).toList());
});

/// Admin-only: live stream of every user.
final adminAllUsersProvider = StreamProvider<List<UserProfile>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('users').snapshots().map(
        (snap) => snap.docs.map(UserProfile.fromFirestore).toList(),
      );
});

/// Computed dashboard headline metrics.
class DashboardStats {
  const DashboardStats({
    required this.pendingReview,
    required this.thisMonthCount,
    required this.thisMonthRevenue,
    required this.activeLive,
  });

  final int pendingReview;
  final int thisMonthCount;
  final int thisMonthRevenue;
  final int activeLive;

  static const empty = DashboardStats(
    pendingReview: 0,
    thisMonthCount: 0,
    thisMonthRevenue: 0,
    activeLive: 0,
  );

  factory DashboardStats.from(List<Booking> bookings) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    var pending = 0;
    var monthCount = 0;
    var monthRevenue = 0;
    var live = 0;
    for (final b in bookings) {
      switch (b.status) {
        case BookingStatus.pending:
          pending++;
          break;
        case BookingStatus.live:
          live++;
          break;
        default:
          break;
      }
      final created = b.createdAt;
      if (created != null && !created.isBefore(monthStart)) {
        monthCount++;
        if (b.status != BookingStatus.cancelled &&
            b.status != BookingStatus.rejected &&
            b.status != BookingStatus.draft) {
          monthRevenue += b.amount;
        }
      }
    }
    return DashboardStats(
      pendingReview: pending,
      thisMonthCount: monthCount,
      thisMonthRevenue: monthRevenue,
      activeLive: live,
    );
  }
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final async = ref.watch(adminAllBookingsProvider);
  return async.maybeWhen(
    data: DashboardStats.from,
    orElse: () => DashboardStats.empty,
  );
});

/// Five most recent bookings — feeds the "Recent activity" panel.
final recentBookingsProvider = Provider<List<Booking>>((ref) {
  final async = ref.watch(adminAllBookingsProvider);
  final all = async.asData?.value ?? const [];
  return all.take(8).toList();
});

/// Maximum minutes a booking is allowed to sit in pending review before it
/// gets flagged on the dashboard as overdue.
const int kStalePendingThresholdMinutes = 60;

/// A pending-review booking that has been waiting longer than the SLA.
/// `pendingForMinutes` is how many minutes it has been sitting in the queue.
class StalePending {
  const StalePending({
    required this.booking,
    required this.pendingForMinutes,
  });
  final Booking booking;
  final int pendingForMinutes;
}

/// Pending-review bookings whose age is past the stale threshold.
/// Sorted oldest first so the most overdue is at the top.
final stalePendingBookingsProvider = Provider<List<StalePending>>((ref) {
  final async = ref.watch(adminAllBookingsProvider);
  final all = async.asData?.value ?? const [];
  final now = DateTime.now();
  final out = <StalePending>[];
  for (final b in all) {
    if (b.status != BookingStatus.pending) continue;
    final created = b.createdAt;
    if (created == null) continue;
    final mins = now.difference(created).inMinutes;
    if (mins < kStalePendingThresholdMinutes) continue;
    out.add(StalePending(booking: b, pendingForMinutes: mins));
  }
  out.sort((a, b) => b.pendingForMinutes.compareTo(a.pendingForMinutes));
  return out;
});

// Re-export the existing pending stream for shared use.
final adminPendingBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final repo = ref.watch(bookingsRepositoryProvider);
  return repo.adminWatchByStatus(BookingStatus.pending.storageValue);
});

// Suppress unused-import lint if Timestamp isn't referenced directly.
// ignore: unused_element
Timestamp _t() => Timestamp.now();
