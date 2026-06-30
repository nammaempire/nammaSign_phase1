import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/legal_repository.dart';
import '../../domain/legal_page.dart';

/// Live stream of one legal page (Privacy / Terms / Content Guidelines).
/// Keyed by page id so callers can write
/// `ref.watch(legalPageProvider(LegalPageId.privacy))`.
final legalPageProvider =
    StreamProvider.family<LegalPage?, String>((ref, pageId) {
  return ref.watch(legalRepositoryProvider).watchById(pageId);
});

/// Admin-only stream of every page. Used by the admin CMS to render
/// the list of editable pages.
final adminLegalPagesProvider = StreamProvider<List<LegalPage>>((ref) {
  return ref.watch(legalRepositoryProvider).adminWatchAll();
});
