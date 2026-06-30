import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/legal_page.dart';
import '../providers/legal_provider.dart';

/// Reading view for one of the three legal pages.
///
/// The body is plain text with paragraph breaks. Lines written entirely
/// in uppercase are treated as section headings and rendered slightly
/// larger / bolder. This lets the admin write structured copy from the
/// CMS without needing a full markdown editor.
class LegalPageScreen extends ConsumerWidget {
  const LegalPageScreen({super.key, required this.pageId});
  final String pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(legalPageProvider(pageId));
    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: AppBar(
        backgroundColor: context.colors.bg,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: context.colors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text(
          _shortTitle(pageId),
          style: AppTextStyles.brandHuge.copyWith(
            fontSize: 22,
            color: context.colors.textPrimary,
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "Couldn't load this page.\n$e",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ),
        data: (page) =>
            page == null ? const _NotYetPublished() : _Body(page: page),
      ),
    );
  }

  static String _shortTitle(String id) => switch (id) {
        LegalPageId.privacy => 'Privacy policy',
        LegalPageId.terms => 'Terms of service',
        LegalPageId.content => 'Content guidelines',
        _ => 'Legal',
      };
}

class _Body extends StatelessWidget {
  const _Body({required this.page});
  final LegalPage page;

  @override
  Widget build(BuildContext context) {
    final effective = page.effectiveFrom ?? page.updatedAt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      children: [
        Text(
          page.title,
          style: AppTextStyles.brandHuge.copyWith(
            fontSize: 26,
            color: context.colors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          [
            'Version ${page.version}',
            if (effective != null)
              'Last updated ${DateFormat('d MMM y').format(effective)}',
          ].join('  ·  '),
          style: AppTextStyles.bodySmall.copyWith(
            color: context.colors.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Render paragraphs. Lines in ALL CAPS get treated as headings,
        // which is the convention the seed copy uses.
        ..._renderBody(context, page.body),
        const SizedBox(height: AppSpacing.xxl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Questions about this page? Email nammaempire@gmail.com.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _renderBody(BuildContext context, String body) {
    final out = <Widget>[];
    final paragraphs = body.replaceAll('\r\n', '\n').split('\n\n');
    for (final raw in paragraphs) {
      final p = raw.trim();
      if (p.isEmpty) continue;
      final isHeading = _looksLikeHeading(p);
      if (isHeading) {
        out.add(Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 6),
          child: Text(
            p,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.primary,
              fontSize: 13,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ));
      } else {
        out.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            p,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.colors.textPrimary,
              height: 1.55,
            ),
          ),
        ));
      }
    }
    return out;
  }

  bool _looksLikeHeading(String line) {
    // No lowercase letters, short-ish, single line.
    if (line.contains('\n')) return false;
    if (line.length > 80) return false;
    final letters = line.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.isEmpty) return false;
    return letters == letters.toUpperCase();
  }
}

class _NotYetPublished extends StatelessWidget {
  const _NotYetPublished();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(32),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.article_outlined,
                size: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "We're publishing this soon",
              style: AppTextStyles.h2.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "If you need a copy in the meantime, email us at "
              "nammaempire@gmail.com.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
