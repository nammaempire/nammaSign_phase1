import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/firebase_providers.dart';
import '../domain/legal_page.dart';

/// Reads + writes the `legalPages/{id}` Firestore documents.
///
/// User-side: anyone (signed-in or not) can watch a single page by id,
/// because the corresponding security rule allows public get when
/// `published == true`. The login footer needs this to work pre-auth.
///
/// Admin-side: list/edit any page including drafts.
class LegalRepository {
  LegalRepository({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('legalPages');

  /// Stream of one specific page. Returns null while loading or if the
  /// doc doesn't exist yet (e.g. before the seed script has run).
  Stream<LegalPage?> watchById(String pageId) {
    return _col.doc(pageId).snapshots().map(
          (snap) => snap.exists ? LegalPage.fromFirestore(snap) : null,
        );
  }

  /// Admin-only — every page, including drafts.
  Stream<List<LegalPage>> adminWatchAll() {
    return _col.snapshots().map(
          (s) => s.docs.map(LegalPage.fromFirestore).toList(),
        );
  }

  /// Admin upsert. Always uses the well-known id, so calling this on a
  /// page that doesn't exist yet creates it cleanly.
  Future<void> adminSave(LegalPage page) {
    return _col.doc(page.id).set(
          page.toFirestore(),
          SetOptions(merge: true),
        );
  }
}

final legalRepositoryProvider = Provider<LegalRepository>(
  (ref) => LegalRepository(firestore: ref.watch(firestoreProvider)),
);
