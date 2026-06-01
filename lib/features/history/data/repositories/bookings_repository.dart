import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/booking.dart';

abstract class BookingsRepository {
  Stream<List<Booking>> watchForUser(String userId);
  Stream<Booking?> watchOne(String id);
  Future<Booking?> getById(String id);
  Future<String> create(Booking booking);
  Future<void> update(String id, Map<String, dynamic> patch);

  // ---- Admin reads + writes (gated by isAdmin in firestore.rules) ----

  /// Admin: live list of bookings with a given status, oldest first.
  /// Used to power the admin pending-review queue.
  Stream<List<Booking>> adminWatchByStatus(String storageStatus);

  /// Admin: marks a booking paid (offline payment received).
  Future<void> adminMarkPaid(String id, {String? paymentRef});

  /// Admin: approves a booking → flips to `live`, sets the active window,
  /// and records the reviewer's name. Throws if the booking isn't paid yet.
  Future<void> adminApprove(
    String id, {
    required DateTime scheduledStartAt,
    required DateTime scheduledEndAt,
    required String reviewerName,
  });

  /// Admin: rejects a booking with a typed reason + rule code.
  Future<void> adminReject(
    String id, {
    required String reason,
    String? ruleCode,
    required String reviewerName,
  });
}

class FirestoreBookingsRepository implements BookingsRepository {
  FirestoreBookingsRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.bookings);

  @override
  Stream<List<Booking>> watchForUser(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map(Booking.fromFirestore)
          .where((b) => b.status.isVisibleInHistory)
          .toList();
    });
  }

  @override
  Stream<Booking?> watchOne(String id) {
    return _col.doc(id).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Booking.fromFirestore(snap);
    });
  }

  @override
  Future<Booking?> getById(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) return null;
    return Booking.fromFirestore(snap);
  }

  @override
  Future<String> create(Booking booking) async {
    final ref = await _col.add(booking.toFirestore());
    return ref.id;
  }

  @override
  Future<void> update(String id, Map<String, dynamic> patch) async {
    patch['updatedAt'] = FieldValue.serverTimestamp();
    await _col.doc(id).update(patch);
  }

  // ---- Admin ----------------------------------------------------------------

  @override
  Stream<List<Booking>> adminWatchByStatus(String storageStatus) {
    return _col
        .where('status', isEqualTo: storageStatus)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(Booking.fromFirestore).toList());
  }

  @override
  Future<void> adminMarkPaid(String id, {String? paymentRef}) async {
    await _col.doc(id).update({
      'paid': true,
      'paidAt': FieldValue.serverTimestamp(),
      if (paymentRef != null && paymentRef.isNotEmpty)
        'paymentRef': paymentRef,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> adminApprove(
    String id, {
    required DateTime scheduledStartAt,
    required DateTime scheduledEndAt,
    required String reviewerName,
  }) async {
    await _col.doc(id).update({
      'status': 'live',
      'scheduledStartAt': Timestamp.fromDate(scheduledStartAt),
      'scheduledEndAt': Timestamp.fromDate(scheduledEndAt),
      'review': {
        'reviewerName': reviewerName,
        'reviewedAt': FieldValue.serverTimestamp(),
        'decision': 'approved',
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> adminReject(
    String id, {
    required String reason,
    String? ruleCode,
    required String reviewerName,
  }) async {
    await _col.doc(id).update({
      'status': 'rejected',
      'review': {
        'reviewerName': reviewerName,
        'reviewedAt': FieldValue.serverTimestamp(),
        'decision': 'rejected',
        'reason': reason,
        if (ruleCode != null && ruleCode.isNotEmpty) 'ruleCode': ruleCode,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
