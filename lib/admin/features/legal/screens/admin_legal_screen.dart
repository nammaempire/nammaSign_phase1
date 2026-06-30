import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../features/legal/data/legal_repository.dart';
import '../../../../features/legal/domain/legal_page.dart';
import '../../../../features/legal/presentation/providers/legal_provider.dart';
import '../../../app/admin_routes.dart';
import '../../../shared/theme/admin_theme.dart';
import '../../../shared/widgets/admin_shell.dart';
import '../widgets/edit_legal_dialog.dart';

class AdminLegalScreen extends ConsumerWidget {
  const AdminLegalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminLegalPagesProvider);

    return AdminShell(
      section: AdminSection.legal,
      title: 'Legal pages',
      subtitle: 'Privacy Policy · Terms · Content Guidelines',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Couldn't load legal pages\n$e")),
        data: (existing) {
          // Build a map keyed by id so we can render fixed cards for the
          // three well-known pages even if some don't exist in Firestore
          // yet (which is exactly the state before the seed script runs).
          final byId = {for (final p in existing) p.id: p};
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AdminSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final id in LegalPageId.all)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AdminSpacing.lg),
                    child: _LegalCard(
                      pageId: id,
                      page: byId[id],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LegalCard extends ConsumerWidget {
  const _LegalCard({required this.pageId, required this.page});
  final String pageId;
  final LegalPage? page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMissing = page == null;
    final hint = switch (pageId) {
      LegalPageId.privacy => 'Customer-facing Privacy Notice — required '
          'by India\'s DPDPA 2023 and by Apple / Play store listing.',
      LegalPageId.terms => 'Terms of service the user accepts at signup.',
      LegalPageId.content => 'What ad creatives are allowed on the boards.',
      _ => '',
    };
    final defaultTitle = switch (pageId) {
      LegalPageId.privacy => 'Privacy Policy',
      LegalPageId.terms => 'Terms of Service',
      LegalPageId.content => 'Content Guidelines',
      _ => 'Legal page',
    };

    return Container(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AdminColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              switch (pageId) {
                LegalPageId.privacy => Icons.lock_outline_rounded,
                LegalPageId.terms => Icons.description_outlined,
                LegalPageId.content => Icons.policy_outlined,
                _ => Icons.article_outlined,
              },
              color: AdminColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      page?.title ?? defaultTitle,
                      style: AdminText.h1.copyWith(fontSize: 18),
                    ),
                    const SizedBox(width: 10),
                    if (page != null) _StatusPill(published: page!.published),
                    if (isMissing) const _MissingPill(),
                  ],
                ),
                const SizedBox(height: 4),
                if (page != null)
                  Text(
                    'Version ${page!.version}'
                    '${page!.updatedAt != null ? ' · Last updated ${DateFormat('d MMM y · HH:mm').format(page!.updatedAt!)}' : ''}',
                    style: AdminText.bodySmall,
                  )
                else
                  Text(hint, style: AdminText.bodySmall),
                const SizedBox(height: 10),
                if (page != null)
                  Text(
                    page!.body.length > 200
                        ? '${page!.body.substring(0, 200)}…'
                        : page!.body,
                    style: AdminText.bodyMedium.copyWith(
                      color: AdminColors.textMuted,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AdminSpacing.md),
          FilledButton.icon(
            icon: Icon(isMissing ? Icons.add_rounded : Icons.edit_outlined,
                size: 18),
            label: Text(isMissing ? 'Create' : 'Edit'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => EditLegalDialog(
                pageId: pageId,
                existing: page,
                defaultTitle: defaultTitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.published});
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

class _MissingPill extends StatelessWidget {
  const _MissingPill();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AdminColors.dangerBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'NOT YET PUBLISHED',
        style: TextStyle(
          color: AdminColors.danger,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 1.3,
        ),
      ),
    );
  }
}
