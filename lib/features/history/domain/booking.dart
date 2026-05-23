import 'package:flutter/material.dart';

enum BookingStatus { live, pending, rejected }

extension BookingStatusX on BookingStatus {
  String get label => switch (this) {
        BookingStatus.live => 'LIVE',
        BookingStatus.pending => 'PENDING',
        BookingStatus.rejected => 'REJECTED',
      };

  /// Tint used on the status pill background.
  Color get tint => switch (this) {
        BookingStatus.live => const Color(0xFFDAF5E0),
        BookingStatus.pending => const Color(0xFFFCE7C2),
        BookingStatus.rejected => const Color(0xFFF4DCDF),
      };

  /// Text + dot color on the status pill, and the icon container fill.
  Color get accent => switch (this) {
        BookingStatus.live => const Color(0xFF3B7F2A),
        BookingStatus.pending => const Color(0xFFB7791F),
        BookingStatus.rejected => const Color(0xFFB7245B),
      };

  /// Big icon container gradient (left side of the card).
  LinearGradient get iconGradient => switch (this) {
        BookingStatus.live => const LinearGradient(
            colors: [Color(0xFF8FB13D), Color(0xFF6E8E1F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        BookingStatus.pending => const LinearGradient(
            colors: [Color(0xFF7B2FE3), Color(0xFF4A1A9C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        BookingStatus.rejected => const LinearGradient(
            colors: [Color(0xFFE5559B), Color(0xFFA3296C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
      };

  IconData get icon => switch (this) {
        BookingStatus.live => Icons.play_arrow_rounded,
        BookingStatus.pending => Icons.schedule_rounded,
        BookingStatus.rejected => Icons.schedule_rounded,
      };
}

class Booking {
  const Booking({
    required this.id,
    required this.campaignTitle,
    required this.location,
    required this.boardType,
    required this.durationDays,
    required this.runDateLabel,
    required this.amount,
    required this.paymentMethod,
    required this.paid,
    required this.status,
    this.adminNote,
  });

  final String id;
  final String campaignTitle;
  final String location;
  final String boardType;
  final int durationDays;
  final String runDateLabel; // e.g. "27 Oct"
  final int amount;
  final String paymentMethod; // e.g. "UPI"
  final bool paid;
  final BookingStatus status;
  final String? adminNote; // only when rejected
}

/// In-memory sample bookings for the UI demo.
const List<Booking> sampleBookings = [
  Booking(
    id: '1',
    campaignTitle: 'Brigade Corner Launch',
    location: '100 Feet Road',
    boardType: 'LED Hoarding',
    durationDays: 15,
    runDateLabel: '27 Oct',
    amount: 7328,
    paymentMethod: 'UPI',
    paid: true,
    status: BookingStatus.live,
  ),
  Booking(
    id: '2',
    campaignTitle: "Anjali's Birthday",
    location: 'Forum Mall',
    boardType: 'Atrium Screen',
    durationDays: 1,
    runDateLabel: '22 May',
    amount: 920,
    paymentMethod: 'UPI',
    paid: true,
    status: BookingStatus.pending,
  ),
  Booking(
    id: '3',
    campaignTitle: 'Cornerstone Realty',
    location: '100 Feet Road',
    boardType: 'LED Hoarding',
    durationDays: 15,
    runDateLabel: '26 Oct',
    amount: 6900,
    paymentMethod: 'UPI',
    paid: true,
    status: BookingStatus.rejected,
    adminNote: 'Exceeds 30% text rule. Edit creative and resubmit.',
  ),
  Booking(
    id: '4',
    campaignTitle: 'Festival Sale',
    location: 'MG Road',
    boardType: 'Digital Tower',
    durationDays: 7,
    runDateLabel: '14 Nov',
    amount: 4340,
    paymentMethod: 'UPI',
    paid: true,
    status: BookingStatus.live,
  ),
];
