/// Computes line items + total for a booking.
///
/// Pricing rules (Phase 1a — match the design):
///   - subtotal     = daily rate × duration
///   - 8% discount  for 15-29 day bookings
///   - 15% discount for 30+ day bookings
///   - GST 18%      on (subtotal - discount)
class BookingTotals {
  const BookingTotals({
    required this.subtotal,
    required this.discount,
    required this.gst,
    required this.total,
  });

  final int subtotal;
  final int discount;
  final int gst;
  final int total;

  static BookingTotals compute({
    required int dailyRate,
    required int durationDays,
  }) {
    final subtotal = dailyRate * durationDays;
    final discountPct = switch (durationDays) {
      >= 30 => 0.15,
      >= 15 => 0.08,
      _ => 0.0,
    };
    final discount = (subtotal * discountPct).round();
    final taxable = subtotal - discount;
    final gst = (taxable * 0.18).round();
    return BookingTotals(
      subtotal: subtotal,
      discount: discount,
      gst: gst,
      total: taxable + gst,
    );
  }
}

/// Formats integer rupees with thousand separators (Indian numbering style
/// would be 7,32,800 but the design uses plain comma grouping, so we do too).
String formatRupees(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
