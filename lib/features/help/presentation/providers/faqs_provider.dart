import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/faqs_repository.dart';
import '../../domain/help_faq.dart';

/// Live stream of published FAQs for the user-facing Help screen.
final publishedFaqsProvider = StreamProvider<List<HelpFaq>>((ref) {
  return ref.watch(faqsRepositoryProvider).watchPublished();
});

/// Live stream of every FAQ (including drafts) — admin only.
final adminAllFaqsProvider = StreamProvider<List<HelpFaq>>((ref) {
  return ref.watch(faqsRepositoryProvider).adminWatchAll();
});

/// Grouped view: `{category: [faqs]}` in display order. Used by both the
/// user Help screen and the admin CMS to render each category as a
/// section.
final groupedPublishedFaqsProvider =
    Provider<Map<FaqCategory, List<HelpFaq>>>((ref) {
  final async = ref.watch(publishedFaqsProvider);
  final list = async.asData?.value ?? const [];
  return _groupByCategory(list);
});

final groupedAdminFaqsProvider =
    Provider<Map<FaqCategory, List<HelpFaq>>>((ref) {
  final async = ref.watch(adminAllFaqsProvider);
  final list = async.asData?.value ?? const [];
  return _groupByCategory(list);
});

Map<FaqCategory, List<HelpFaq>> _groupByCategory(List<HelpFaq> list) {
  final out = <FaqCategory, List<HelpFaq>>{};
  for (final c in FaqCategory.displayOrder) {
    out[c] = const [];
  }
  for (final f in list) {
    out[f.category] = [...(out[f.category] ?? const []), f];
  }
  return out;
}
