import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/history/domain/booking.dart';
import '../../../app/admin_routes.dart';
import '../../../shared/theme/admin_theme.dart';
import '../../../shared/widgets/admin_shell.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? 'admin';
    final greeting = _greeting();
    return AdminShell(
      section: AdminSection.dashboard,
      title: '$greeting, ${email.split('@').first}',
      subtitle: DateFormat('EEEE, d MMMM y').format(DateTime.now()),
      child: const SingleChildScrollView(
        padding: EdgeInsets.all(AdminSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StaleAlertCard(),
            _MetricGrid(),
            SizedBox(height: AdminSpacing.xxl),
            _RecentBookingsPanel(),
          ],
        ),
      ),
    );
  }

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _MetricGrid extends ConsumerWidget {
  const _MetricGrid();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    return LayoutBuilder(builder: (ctx, c) {
      // Wrap to 2 columns on narrow widths.
      final isWide = c.maxWidth > 900;
      final cards = [
        _MetricCard(
          icon: Icons.inbox_outlined,
          iconBg: AdminColors.warningBg,
          iconFg: AdminColors.warning,
          label: 'PENDING REVIEW',
          value: '${stats.pendingReview}',
          subtitle: stats.pendingReview == 0
              ? 'Inbox zero'
              : 'Awaiting your decision',
          tappable: () => ctx.go(AdminRoutes.bookings),
        ),
        _MetricCard(
          icon: Icons.adjust_rounded,
          iconBg: AdminColors.successBg,
          iconFg: AdminColors.success,
          label: 'LIVE CAMPAIGNS',
          value: '${stats.activeLive}',
          subtitle: 'Running on boards',
        ),
        _MetricCard(
          icon: Icons.currency_rupee_rounded,
          iconBg: AdminColors.primarySurface,
          iconFg: AdminColors.primary,
          label: 'REVENUE · THIS MONTH',
          value: '₹${_compact(stats.thisMonthRevenue)}',
          subtitle: 'Approved bookings',
        ),
        _MetricCard(
          icon: Icons.calendar_today_outlined,
          iconBg: AdminColors.infoBg,
          iconFg: AdminColors.info,
          label: 'BOOKINGS · THIS MONTH',
          value: '${stats.thisMonthCount}',
          subtitle: 'All submissions',
        ),
      ];
      return GridView.count(
        crossAxisCount: isWide ? 4 : 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AdminSpacing.md,
        crossAxisSpacing: AdminSpacing.md,
        childAspectRatio: isWide ? 2.4 : 1.8,
        children: cards,
      );
    });
  }

  static String _compact(int n) {
    if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(1)}Cr';
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return n.toString();
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.label,
    required this.value,
    required this.subtitle,
    this.tappable,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String label;
  final String value;
  final String subtitle;
  final VoidCallback? tappable;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconFg, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: AdminText.caps.copyWith(fontSize: 10)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AdminText.metricValue.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AdminText.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (tappable == null) return child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: tappable, child: child),
    );
  }
}

class _RecentBookingsPanel extends ConsumerWidget {
  const _RecentBookingsPanel();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(recentBookingsProvider);
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(14),
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
                Text('Recent bookings', style: AdminText.h1.copyWith(fontSize: 18)),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go(AdminRoutes.bookings),
                  child: const Text('View all'),
                ),
              ],
            ),
          ),
          if (bookings.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AdminSpacing.xl,
                0,
                AdminSpacing.xl,
                AdminSpacing.xxl,
              ),
              child: _DashEmptyState(),
            )
          else
            ...bookings.map((b) => _BookingTile(booking: b)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(AdminRoutes.bookingDetailFor(booking.id)),
      hoverColor: AdminColors.hover,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.xl,
          vertical: AdminSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AdminColors.border)),
        ),
        child: Row(
          children: [
            _StatusDot(status: booking.status),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.campaignTitle,
                    style: AdminText.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${booking.location} · ${booking.durationDays} day'
                    '${booking.durationDays == 1 ? '' : 's'}',
                    style: AdminText.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                booking.status.label,
                style: AdminText.caps.copyWith(
                  color: booking.status.accent,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '₹${NumberFormat.decimalPattern('en_IN').format(booking.amount)}',
                style: AdminText.label,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                booking.createdAt == null
                    ? '—'
                    : DateFormat('d MMM · HH:mm').format(booking.createdAt!),
                style: AdminText.bodySmall,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AdminColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final BookingStatus status;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: status.accent,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Pulsing red alert card. Surfaces pending bookings that have exceeded the
/// 1-hour SLA so the admin can act on them immediately.
class _StaleAlertCard extends ConsumerWidget {
  const _StaleAlertCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stale = ref.watch(stalePendingBookingsProvider);
    if (stale.isEmpty) return const SizedBox.shrink();

    final mostOverdue = stale.first;
    final extraCount = stale.length - 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.xxl),
      child: _BlinkingBox(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go(AdminRoutes.bookings),
            child: Container(
              padding: const EdgeInsets.all(AdminSpacing.xl),
              decoration: BoxDecoration(
                color: AdminColors.dangerBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.danger, width: 2),
              ),
              child: Row(
                children: [
                  _PulsingIcon(),
                  const SizedBox(width: AdminSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AdminColors.danger,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'OVERDUE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${stale.length} pending '
                              'booking${stale.length == 1 ? '' : 's'} '
                              'waiting > 1 hour',
                              style: AdminText.label.copyWith(
                                color: AdminColors.danger,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          extraCount == 0
                              ? '"${mostOverdue.booking.campaignTitle}" '
                                  'has been waiting '
                                  '${_humanDuration(mostOverdue.pendingForMinutes)}.'
                              : '"${mostOverdue.booking.campaignTitle}" '
                                  'has been waiting '
                                  '${_humanDuration(mostOverdue.pendingForMinutes)} '
                                  '· $extraCount more overdue.',
                          style: AdminText.bodyMedium.copyWith(
                            color: AdminColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AdminSpacing.md),
                  FilledButton.icon(
                    onPressed: () => context.go(AdminRoutes.bookings),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Review now'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AdminColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _humanDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

/// Wraps a child with a gentle opacity pulse so the alert pulls focus
/// without being epileptic-flashy.
class _BlinkingBox extends StatefulWidget {
  const _BlinkingBox({required this.child});
  final Widget child;
  @override
  State<_BlinkingBox> createState() => _BlinkingBoxState();
}

class _BlinkingBoxState extends State<_BlinkingBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.55).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

class _PulsingIcon extends StatefulWidget {
  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final scale = 1.0 + (_ctrl.value * 0.12);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AdminColors.danger,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.priority_high_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        );
      },
    );
  }
}

class _DashEmptyState extends StatelessWidget {
  const _DashEmptyState();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xxl),
      child: Column(
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
              Icons.inbox_outlined,
              color: AdminColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No bookings yet',
            style: AdminText.h1.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Once customers submit campaigns they\'ll show up here.',
            style: AdminText.bodyMedium,
          ),
        ],
      ),
    );
  }
}
