import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum BookingStatus {
  draft,
  pendingPayment,
  pending, // == pending_review on backend (admin queue)
  live,
  rejected,
  completed,
  cancelled,
}

extension BookingStatusX on BookingStatus {
  String get storageValue => switch (this) {
        BookingStatus.draft => 'draft',
        BookingStatus.pendingPayment => 'pending_payment',
        BookingStatus.pending => 'pending_review',
        BookingStatus.live => 'live',
        BookingStatus.rejected => 'rejected',
        BookingStatus.completed => 'completed',
        BookingStatus.cancelled => 'cancelled',
      };

  static BookingStatus fromStorage(String? raw) {
    return switch (raw) {
      'draft' => BookingStatus.draft,
      'pending_payment' => BookingStatus.pendingPayment,
      'pending_review' => BookingStatus.pending,
      'live' => BookingStatus.live,
      'rejected' => BookingStatus.rejected,
      'completed' => BookingStatus.completed,
      'cancelled' => BookingStatus.cancelled,
      _ => BookingStatus.pending,
    };
  }

  /// Whether to show this booking on history list. Drafts are hidden.
  bool get isVisibleInHistory => this != BookingStatus.draft;

  String get label => switch (this) {
        BookingStatus.live => 'LIVE',
        BookingStatus.pending => 'PENDING',
        BookingStatus.pendingPayment => 'AWAITING PAYMENT',
        BookingStatus.rejected => 'REJECTED',
        BookingStatus.completed => 'COMPLETED',
        BookingStatus.cancelled => 'CANCELLED',
        BookingStatus.draft => 'DRAFT',
      };

  Color get tint => switch (this) {
        BookingStatus.live => const Color(0xFFDAF5E0),
        BookingStatus.pending ||
        BookingStatus.pendingPayment =>
          const Color(0xFFFCE7C2),
        BookingStatus.rejected => const Color(0xFFF4DCDF),
        BookingStatus.completed => const Color(0xFFE5D9FF),
        BookingStatus.cancelled => const Color(0xFFEEEEEE),
        BookingStatus.draft => const Color(0xFFEEEEEE),
      };

  Color get accent => switch (this) {
        BookingStatus.live => const Color(0xFF3B7F2A),
        BookingStatus.pending ||
        BookingStatus.pendingPayment =>
          const Color(0xFFB7791F),
        BookingStatus.rejected => const Color(0xFFB7245B),
        BookingStatus.completed => const Color(0xFF4A1A9C),
        BookingStatus.cancelled ||
        BookingStatus.draft =>
          const Color(0xFF6E6E7C),
      };

  LinearGradient get iconGradient => switch (this) {
        BookingStatus.live => const LinearGradient(
            colors: [Color(0xFF8FB13D), Color(0xFF6E8E1F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        BookingStatus.rejected => const LinearGradient(
            colors: [Color(0xFFE5559B), Color(0xFFA3296C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        _ => const LinearGradient(
            colors: [Color(0xFF7B2FE3), Color(0xFF4A1A9C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
      };

  IconData get icon => switch (this) {
        BookingStatus.live => Icons.play_arrow_rounded,
        _ => Icons.schedule_rounded,
      };
}

/// A booking — submitted, approved, live, completed, or rejected.
///
/// Mirrors the `bookings/{id}` Firestore document defined in
/// FIREBASE_ARCHITECTURE.md.
class Booking {
  const Booking({
    required this.id,
    required this.userId,
    required this.areaId,
    required this.campaignTitle,
    required this.location,
    required this.boardType,
    required this.durationDays,
    required this.runDateLabel,
    required this.amount,
    required this.paymentMethod,
    required this.paid,
    required this.status,
    this.description,
    this.creativeUrl,
    this.creativeUrls = const [],
    this.creativeIsVideo = false,
    this.adminNote,
    this.adminRuleCode,
    this.adminReviewerName,
    this.createdAt,
    this.scheduledStartAt,
    this.scheduledEndAt,
    this.actualPlays = 0,
    this.targetPlays = 0,
    this.paymentLinkUrl,
  });

  // Core
  final String id;
  final String userId;
  final String areaId;

  // Display
  final String campaignTitle;
  final String location;
  final String boardType;

  // Duration + pricing
  final int durationDays;
  final String runDateLabel;
  final int amount;
  final String paymentMethod;
  final bool paid;

  // Status + workflow
  final BookingStatus status;
  final String? description;
  final String? creativeUrl;
  final List<String> creativeUrls;
  final bool creativeIsVideo;
  final String? adminNote;
  final String? adminRuleCode;
  final String? adminReviewerName;

  // Tracking
  final DateTime? createdAt;
  final DateTime? scheduledStartAt;
  final DateTime? scheduledEndAt;
  final int actualPlays;
  final int targetPlays;

  /// Razorpay hosted payment link URL — present while a booking is
  /// pending_payment so the user can re-open the checkout page.
  final String? paymentLinkUrl;

  factory Booking.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final d = snap.data() ?? const <String, dynamic>{};
    final pricing = (d['pricing'] as Map<String, dynamic>?) ?? {};
    final creative = (d['creative'] as Map<String, dynamic>?) ?? {};
    final review = (d['review'] as Map<String, dynamic>?) ?? {};

    return Booking(
      id: snap.id,
      userId: (d['userId'] as String?) ?? '',
      areaId: (d['areaId'] as String?) ?? '',
      campaignTitle: (d['campaignTitle'] as String?) ?? 'Untitled',
      location: (d['locationLabel'] as String?) ??
          (d['areaId'] as String?) ??
          '',
      boardType: (d['boardTypeLabel'] as String?) ?? '4 LED Boards',
      durationDays: (d['durationDays'] as num?)?.toInt() ?? 1,
      runDateLabel: _formatRunDate(d['scheduledStartAt'] as Timestamp?),
      amount: (pricing['total'] as num?)?.toInt() ?? 0,
      paymentMethod: (d['paymentMethod'] as String?) ?? 'UPI',
      paid: (d['paid'] as bool?) ?? false,
      status: BookingStatusX.fromStorage(d['status'] as String?),
      description: d['description'] as String?,
      creativeUrl: creative['url'] as String?,
      creativeUrls: (creative['urls'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      creativeIsVideo: (creative['type'] as String?) == 'video',
      adminNote: review['reason'] as String?,
      adminRuleCode: review['ruleCode'] as String?,
      adminReviewerName: review['reviewerName'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      scheduledStartAt: (d['scheduledStartAt'] as Timestamp?)?.toDate(),
      scheduledEndAt: (d['scheduledEndAt'] as Timestamp?)?.toDate(),
      actualPlays: (d['actualPlays'] as num?)?.toInt() ?? 0,
      targetPlays: (d['targetPlays'] as num?)?.toInt() ?? 0,
      paymentLinkUrl: d['paymentLinkUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'areaId': areaId,
        'campaignTitle': campaignTitle,
        'description': description,
        'durationDays': durationDays,
        'locationLabel': location,
        'boardTypeLabel': boardType,
        'paymentMethod': paymentMethod,
        'paid': paid,
        'status': status.storageValue,
        'creative': {
          'url': creativeUrl,
          'type': creativeIsVideo ? 'video' : 'image',
          'urls': creativeUrls,
        },
        'pricing': {
          'total': amount,
        },
        'actualPlays': actualPlays,
        'targetPlays': targetPlays,
        'createdAt':
            createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
        'updatedAt': FieldValue.serverTimestamp(),
        if (scheduledStartAt != null)
          'scheduledStartAt': Timestamp.fromDate(scheduledStartAt!),
        if (scheduledEndAt != null)
          'scheduledEndAt': Timestamp.fromDate(scheduledEndAt!),
      };

  static String _formatRunDate(Timestamp? ts) {
    if (ts == null) return '—';
    final d = ts.toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}
