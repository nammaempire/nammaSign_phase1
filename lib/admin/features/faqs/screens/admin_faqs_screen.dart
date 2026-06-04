import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/help/data/faqs_repository.dart';
import '../../../../features/help/domain/help_faq.dart';
import '../../../../features/help/presentation/providers/faqs_provider.dart';
import '../../../app/admin_routes.dart';
import '../../../shared/theme/admin_theme.dart';
import '../../../shared/widgets/admin_shell.dart';
import '../widgets/edit_faq_dialog.dart';

class AdminFaqsScreen extends ConsumerWidget {
  const AdminFaqsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminAllFaqsProvider);
    final grouped = ref.watch(groupedAdminFaqsProvider);

    return AdminShell(
      section: AdminSection.faqs,
      title: 'Help & FAQs',
      subtitle: 'Manage what users see on the Help screen',
      actions: [
        FilledButton.icon(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const EditFaqDialog(),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add FAQ'),
        ),
      ],
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Couldn't load FAQs\n$e")),
        data: (faqs) {
          if (faqs.isEmpty) return const _AdminFaqsEmpty();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AdminSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final c in FaqCategory.displayOrder)
                  if ((grouped[c] ?? const []).isNotEmpty) ...[
                    _CategorySection(
                      category: c,
                      items: grouped[c]!,
                    ),
                    const SizedBox(height: AdminSpacing.xxl),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection({required this.category, required this.items});
  final FaqCategory category;
  final List<HelpFaq> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AdminSpacing.xl,
              AdminSpacing.xl,
              AdminSpacing.xl,
              AdminSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AdminColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    category.icon,
                    color: AdminColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  category.label,
                  style: AdminText.h1.copyWith(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  '· ${items.length}',
                  style: AdminText.bodySmall,
                ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++)
            _FaqRow(faq: items[i], isFirst: i == 0),
        ],
      ),
    );
  }
}

class _FaqRow extends ConsumerWidget {
  const _FaqRow({required this.faq, required this.isFirst});
  final HelpFaq faq;
  final bool isFirst;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.xl,
        vertical: AdminSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        faq.question,
                        style: AdminText.label.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _PublishedPill(published: faq.published),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  faq.answer,
                  style: AdminText.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Display order: ${faq.order}',
                  style: AdminText.bodySmall.copyWith(
                    color: AdminColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AdminSpacing.md),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => EditFaqDialog(existing: faq),
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: AdminColors.danger,
            ),
            onPressed: () => _confirmDelete(context, ref, faq),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    HelpFaq faq,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete FAQ?'),
        content: Text('"${faq.question}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.danger,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(faqsRepositoryProvider).adminDelete(faq.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('FAQ deleted.')),
    );
  }
}

class _PublishedPill extends StatelessWidget {
  const _PublishedPill({required this.published});
  final bool published;
  @override
  Widget build(BuildContext context) {
    final bg = published ? AdminColors.successBg : AdminColors.warningBg;
    final fg = published ? AdminColors.success : AdminColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        published ? 'PUBLISHED' : 'DRAFT',
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 1.3,
        ),
      ),
    );
  }
}

class _AdminFaqsEmpty extends StatelessWidget {
  const _AdminFaqsEmpty();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AdminColors.primarySurface,
                borderRadius: BorderRadius.circular(32),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.help_outline_rounded,
                color: AdminColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No FAQs yet',
              style: AdminText.h1.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              "Click 'Add FAQ' to write the first one.",
              style: AdminText.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
