import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/firebase_providers.dart';
import '../domain/app_notification.dart';

/// Reads + mutates the per-user notifications subcollection and manages
/// the user's FCM token list on the `users/{uid}` doc.
class NotificationsRepository {
  NotificationsRepository({
    required this._firestore,
    required this._messaging,
  });

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  /// Live stream of the user's notifications, newest first.
  Stream<List<AppNotification>> watchAll(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .limit(60)
        .snapshots()
        .map((s) => s.docs.map(AppNotification.fromFirestore).toList());
  }

  /// Marks a single notification as read. No-op if already read.
  Future<void> markRead(String uid, String notificationId) async {
    await _col(uid).doc(notificationId).update({'read': true});
  }

  /// Marks every unread notification as read in a single batch.
  Future<void> markAllRead(String uid) async {
    final unread = await _col(uid).where('read', isEqualTo: false).get();
    if (unread.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  /// Adds the current device's FCM token to the user doc if it's not
  /// already there. Tokens are stored as an array on `users/{uid}`.
  ///
  /// Safe to call repeatedly — `arrayUnion` dedupes for us.
  Future<void> registerCurrentToken(String uid) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _firestore.collection('users').doc(uid).set(
      {
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Removes the current device's token. Called on explicit sign-out so
  /// the previous user doesn't keep getting this device's notifications.
  Future<void> unregisterCurrentToken(String uid) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _firestore.collection('users').doc(uid).set(
      {
        'fcmTokens': FieldValue.arrayRemove([token]),
      },
      SetOptions(merge: true),
    );
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(
    firestore: ref.watch(firestoreProvider),
    messaging: ref.watch(firebaseMessagingProvider),
  ),
);
