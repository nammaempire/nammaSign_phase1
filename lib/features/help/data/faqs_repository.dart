import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/firebase_providers.dart';
import '../domain/help_faq.dart';

/// Reads + writes `helpFaqs/{id}`. The user-side and admin-side methods
/// are split so the user query can be safely constrained to published
/// rows (matching the Firestore rule).
class FaqsRepository {
  FaqsRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('helpFaqs');

  /// Stream of every PUBLISHED FAQ, sorted by category then display
  /// order. This is what the user-facing Help screen reads.
  Stream<List<HelpFaq>> watchPublished() {
    return _col
        .where('published', isEqualTo: true)
        .orderBy('category')
        .orderBy('order')
        .snapshots()
        .map((s) => s.docs.map(HelpFaq.fromFirestore).toList());
  }

  /// Stream of ALL FAQs (drafts included). Admin-only.
  Stream<List<HelpFaq>> adminWatchAll() {
    return _col
        .orderBy('category')
        .orderBy('order')
        .snapshots()
        .map((s) => s.docs.map(HelpFaq.fromFirestore).toList());
  }

  /// Admin create — Firestore generates the id.
  Future<String> adminCreate(HelpFaq faq) async {
    final ref = await _col.add(faq.toFirestore());
    return ref.id;
  }

  /// Admin update — patches the existing doc.
  Future<void> adminUpdate(HelpFaq faq) {
    return _col.doc(faq.id).set(
          faq.toFirestore(),
          SetOptions(merge: true),
        );
  }

  /// Admin delete — hard delete. Use `published: false` if you want to
  /// keep history.
  Future<void> adminDelete(String id) => _col.doc(id).delete();
}

final faqsRepositoryProvider = Provider<FaqsRepository>(
  (ref) => FaqsRepository(firestore: ref.watch(firestoreProvider)),
);
