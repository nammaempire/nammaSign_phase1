import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/history/domain/booking.dart';
import '../../dashboard/providers/dashboard_providers.dart';

/// One month's worth of revenue + GST.
class FinanceBucket {
  const FinanceBucket({
    required this.month,
    required this.count,
    required this.gross,
    required this.taxable,
    required this.gst,
  });

  final DateTime month; // first day of that month
  final int count;
  final int gross;
  final int taxable;
  final int gst;

  static FinanceBucket empty(DateTime month) =>
      FinanceBucket(month: month, count: 0, gross: 0, taxable: 0, gst: 0);

  FinanceBucket add(int amount) {
    final t = (amount / 1.18).round();
    final g = amount - t;
    return FinanceBucket(
      month: month,
      count: count + 1,
      gross: gross + amount,
      taxable: taxable + t,
      gst: gst + g,
    );
  }
}

/// Headline GST + revenue numbers across common reporting windows.
class FinanceStats {
  const FinanceStats({
    required this.thisMonth,
    required this.lastMonth,
    required this.thisQuarter,
    required this.thisYear,
    required this.last12Months,
    required this.gstRatePct,
  });

  final FinanceBucket thisMonth;
  final FinanceBucket lastMonth;
  final FinanceBucket thisQuarter;
  final FinanceBucket thisYear;
  final List<FinanceBucket> last12Months; // newest first
  final int gstRatePct;

  static final FinanceStats empty = FinanceStats(
    thisMonth: FinanceBucket(
        month: _zero, count: 0, gross: 0, taxable: 0, gst: 0),
    lastMonth: FinanceBucket(
        month: _zero, count: 0, gross: 0, taxable: 0, gst: 0),
    thisQuarter: FinanceBucket(
        month: _zero, count: 0, gross: 0, taxable: 0, gst: 0),
    thisYear: FinanceBucket(
        month: _zero, count: 0, gross: 0, taxable: 0, gst: 0),
    last12Months: const [],
    gstRatePct: 18,
  );

  static final DateTime _zero = DateTime(1970);

  factory FinanceStats.from(List<Booking> bookings) {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = thisMonthStart;
    final quarterStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
    final yearStart = DateTime(now.year, 1, 1);

    var tm = FinanceBucket.empty(thisMonthStart);
    var lm = FinanceBucket.empty(lastMonthStart);
    var qt = FinanceBucket.empty(quarterStart);
    var yr = FinanceBucket.empty(yearStart);

    // Build a 12-month index keyed by yyyy-mm.
    final months = <DateTime>[];
    final buckets = <String, FinanceBucket>{};
    for (var i = 11; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      months.add(m);
      buckets[_key(m)] = FinanceBucket.empty(m);
    }

    for (final b in bookings) {
      // Only count earned revenue — past admin approval.
      if (b.status != BookingStatus.live &&
          b.status != BookingStatus.completed) {
        continue;
      }
      final at = b.createdAt;
      if (at == null) continue;
      if (!at.isBefore(thisMonthStart)) tm = tm.add(b.amount);
      if (!at.isBefore(lastMonthStart) && at.isBefore(lastMonthEnd)) {
        lm = lm.add(b.amount);
      }
      if (!at.isBefore(quarterStart)) qt = qt.add(b.amount);
      if (!at.isBefore(yearStart)) yr = yr.add(b.amount);

      final k = _key(DateTime(at.year, at.month, 1));
      final existing = buckets[k];
      if (existing != null) buckets[k] = existing.add(b.amount);
    }

    final history = months.reversed
        .map((m) => buckets[_key(m)] ?? FinanceBucket.empty(m))
        .toList();
    return FinanceStats(
      thisMonth: tm,
      lastMonth: lm,
      thisQuarter: qt,
      thisYear: yr,
      last12Months: history,
      gstRatePct: 18,
    );
  }

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';
}

final financeStatsProvider = Provider<FinanceStats>((ref) {
  final async = ref.watch(adminAllBookingsProvider);
  return async.maybeWhen(
    data: FinanceStats.from,
    orElse: () => FinanceStats.empty,
  );
});
