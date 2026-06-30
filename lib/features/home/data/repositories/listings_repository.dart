import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/billboard_listing.dart';

abstract class ListingsRepository {
  /// Streams the full list of area listings, ordered by price ascending.
  Stream<List<BillboardListing>> watchAll();

  /// One-off fetch by id (e.g. used by the booking flow to look up the
  /// listing for a navigation deep-link).
  Future<BillboardListing?> getById(String id);

  /// Admin: create a new area at `areas/{id}`. Throws if it already exists.
  Future<void> adminCreate({
    required String id,
    required BillboardListing listing,
  });

  /// Admin: update an existing area's mutable fields.
  Future<void> adminUpdate(String id, Map<String, dynamic> patch);
}

class FirestoreListingsRepository implements ListingsRepository {
  FirestoreListingsRepository({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.areas);

  @override
  Stream<List<BillboardListing>> watchAll() {
    return _col
        .where('status', isEqualTo: 'active')
        .orderBy('pricePerDay')
        .snapshots()
        .map((snap) =>
            snap.docs.map(BillboardListing.fromFirestore).toList());
  }

  @override
  Future<BillboardListing?> getById(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) return null;
    return BillboardListing.fromFirestore(snap);
  }

  @override
  Future<void> adminCreate({
    required String id,
    required BillboardListing listing,
  }) async {
    final ref = _col.doc(id);
    final existing = await ref.get();
    if (existing.exists) {
      throw StateError('Area "$id" already exists.');
    }
    final data = listing.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
  }

  @override
  Future<void> adminUpdate(String id, Map<String, dynamic> patch) async {
    patch['updatedAt'] = FieldValue.serverTimestamp();
    await _col.doc(id).update(patch);
  }
}
