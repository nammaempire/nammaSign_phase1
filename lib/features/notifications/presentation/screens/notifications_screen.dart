import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/notifications_repository.dart';
import '../../domain/app_notification.dart';
import '../providers/notifications_provider.dart';
import '../../../../app/theme/app_palette.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsStreamProvider);
    final user = ref.watch(currentUserProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: AppBar(
        backgroundColor: context.colors.bg,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
        // Dark status-bar icons (battery, signal, clock) so they're
        // legible against the light app background.
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
          'Notifications',
          style: AppTextStyles.brandHuge.copyWith(
            fontSize: 22,
            color: context.colors.textPrimary,
          ),
        ),
        actions: [
          if (unread > 0 && user != null)
            TextButton(
              onPressed: () => ref
                  .read(notificationsRepositoryProvider)
                  .markAllRead(user.id),
              child: const Text(
                'Mark all read',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "Couldn't load notifications.\n$e",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) return const _EmptyState();
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _NotificationRow(
              notif: items[i],
              onTap: () => _handleTap(context, ref, items[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification n,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user != null && !n.read) {
      await ref
          .read(notificationsRepositoryProvider)
          .markRead(user.id, n.id);
    }
    if (!context.mounted) return;
    final bookingId = n.bookingId;
    if (bookingId != null && bookingId.isNotEmpty) {
      context.push(AppRoutes.campaignStatusFor(bookingId));
    }
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notif, required this.onTap});
  final AppNotification notif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(notif.type);
    return Material(
      color: context.colors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notif.read
                  ? context.colors.surface
                  : AppColors.primary.withValues(alpha: 0.32),
              width: notif.read ? 1 : 1.5,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(_iconFor(notif.type), color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: notif.read
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: context.colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notif.read)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _ago(notif.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(AppNotificationType t) => switch (t) {
        AppNotificationType.paid => Icons.payments_outlined,
        AppNotificationType.live => Icons.play_arrow_rounded,
        AppNotificationType.rejected => Icons.cancel_outlined,
        AppNotificationType.completed => Icons.task_alt_rounded,
        AppNotificationType.unknown => Icons.notifications_outlined,
      };

  static Color _accentFor(AppNotificationType t) => switch (t) {
        AppNotificationType.paid => AppColors.info,
        AppNotificationType.live => AppColors.success,
        AppNotificationType.rejected => AppColors.error,
        AppNotificationType.completed => AppColors.primary,
        AppNotificationType.unknown => AppColors.primary,
      };

  static String _ago(DateTime? d) {
    if (d == null) return 'just now';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(d);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: AppTextStyles.h2.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "We'll let you know when your campaign moves "
              'through review, goes live, or wraps up.',
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
