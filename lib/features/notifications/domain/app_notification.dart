import 'package:cloud_firestore/cloud_firestore.dart';

/// A user-facing notification row, written by the
/// `onBookingStatusChange` / `sweepEndedCampaigns` Cloud Functions
/// into `users/{uid}/notifications/{id}`.
///
/// Mirrors the FCM payload one-to-one so the bell screen and the push
/// banner stay consistent.
enum AppNotificationType {
  paid,
  live,
  rejected,
  completed,
  unknown;

  static AppNotificationType fromStorage(String? raw) => switch (raw) {
        'paid' => AppNotificationType.paid,
        'live' => AppNotificationType.live,
        'rejected' => AppNotificationType.rejected,
        'completed' => AppNotificationType.completed,
        _ => AppNotificationType.unknown,
      };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    this.bookingId,
    this.createdAt,
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final bool read;
  final String? bookingId;
  final DateTime? createdAt;

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final d = snap.data() ?? const <String, dynamic>{};
    return AppNotification(
      id: snap.id,
      type: AppNotificationType.fromStorage(d['type'] as String?),
      title: (d['title'] as String?) ?? 'Notification',
      body: (d['body'] as String?) ?? '',
      read: (d['read'] as bool?) ?? false,
      bookingId: d['bookingId'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
