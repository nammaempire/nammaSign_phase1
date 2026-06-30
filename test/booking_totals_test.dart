// Unit tests for the booking pricing math — the most important logic to
// pin down since it decides what users are charged.
//
// Pricing rules (see BookingTotals):
//   subtotal     = dailyRate * durationDays
//   8% discount  for 15–29 day bookings
//   15% discount for 30+ day bookings
//   GST 18%      on (subtotal - discount)

import 'package:flutter_test/flutter_test.dart';
import 'package:nammasign_phase1/features/booking/domain/booking_totals.dart';

void main() {
  group('BookingTotals.compute', () {
    test('no discount under 15 days', () {
      final t = BookingTotals.compute(dailyRate: 10000, durationDays: 7);
      expect(t.subtotal, 70000);
      expect(t.discount, 0);
      expect(t.gst, 12600); // 70000 * 0.18
      expect(t.total, 82600); // 70000 + 12600
    });

    test('14 days is still the no-discount tier (boundary)', () {
      final t = BookingTotals.compute(dailyRate: 10000, durationDays: 14);
      expect(t.discount, 0);
    });

    test('8% discount kicks in exactly at 15 days', () {
      final t = BookingTotals.compute(dailyRate: 10000, durationDays: 15);
      expect(t.subtotal, 150000);
      expect(t.discount, 12000); // 150000 * 0.08
      expect(t.gst, 24840); // (150000 - 12000) * 0.18
      expect(t.total, 162840); // 138000 + 24840
    });

    test('29 days still on the 8% tier', () {
      final t = BookingTotals.compute(dailyRate: 10000, durationDays: 29);
      expect(t.subtotal, 290000);
      expect(t.discount, 23200); // 290000 * 0.08
      expect(t.gst, 48024); // (290000 - 23200) * 0.18
      expect(t.total, 314824);
    });

    test('15% discount kicks in exactly at 30 days (boundary)', () {
      final t = BookingTotals.compute(dailyRate: 10000, durationDays: 30);
      expect(t.subtotal, 300000);
      expect(t.discount, 45000); // 300000 * 0.15
      expect(t.gst, 45900); // (300000 - 45000) * 0.18
      expect(t.total, 300900); // 255000 + 45900
    });

    test('discount + gst rounding uses round(), not floor', () {
      // dailyRate 333, 15 days -> subtotal 4995; 8% -> 399.6 -> rounds to 400.
      final t = BookingTotals.compute(dailyRate: 333, durationDays: 15);
      expect(t.subtotal, 4995);
      expect(t.discount, 400);
      // taxable 4595; 18% -> 827.1 -> rounds to 827.
      expect(t.gst, 827);
      expect(t.total, 5422);
    });

    test('total always equals (subtotal - discount) + gst', () {
      for (final days in [1, 7, 15, 22, 30, 60, 90]) {
        final t = BookingTotals.compute(dailyRate: 12345, durationDays: days);
        expect(t.total, (t.subtotal - t.discount) + t.gst);
      }
    });
  });

  group('formatRupees', () {
    test('groups in threes with commas', () {
      expect(formatRupees(0), '0');
      expect(formatRupees(100), '100');
      expect(formatRupees(1000), '1,000');
      expect(formatRupees(732800), '732,800');
      expect(formatRupees(1234567), '1,234,567');
    });
  });
}
