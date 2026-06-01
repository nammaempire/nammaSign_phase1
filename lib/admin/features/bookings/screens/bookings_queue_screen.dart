import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../features/history/domain/booking.dart';
import '../../../app/admin_routes.dart';
import '../../../shared/theme/admin_theme.dart';
import '../../../shared/widgets/admin_shell.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../providers/admin_bookings_provider.dart';

class BookingsQueueScreen extends ConsumerWidget {
  const BookingsQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingBookingsStreamProvider);
    return AdminShell(
      section: AdminSection.bookings,
      title: 'Bookings',
      subtitle: 'Pending review queue',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Couldn't load bookings\n$e")),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const _EmptyQueue();
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _BookingRow(booking: bookings[i]),
          );
        },
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.booking});
  final Booking booking;

  bool get _isStale {
    final created = booking.createdAt;
    if (created == null) return false;
    return DateTime.now().difference(created).inMinutes >=
        kStalePendingThresholdMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final stale = _isStale;
    final row = Material(
      color: stale ? AdminColors.dangerBg : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () =>
            context.go(AdminRoutes.bookingDetailFor(booking.id)),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: stale
                  ? AdminColors.danger
                  : Colors.black.withValues(alpha: 0.08),
              width: stale ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _PaidChip(paid: booking.paid),
              if (stale) ...[
                const SizedBox(width: 8),
                const _OverduePill(),
              ],
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.campaignTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${booking.location}  ·  ${booking.boardType}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${booking.durationDays} day'
                  '${booking.durationDays == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '₹${_fmtAmount(booking.amount)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _fmtTimeAgo(booking.createdAt),
                  style: TextStyle(
                    fontSize: 13,
                    color: stale ? AdminColors.danger : Colors.black54,
                    fontWeight: stale ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: stale ? AdminColors.danger : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );

    if (!stale) return row;
    return _QueueBlink(child: row);
  }

  static String _fmtAmount(int n) =>
      NumberFormat.decimalPattern('en_IN').format(n);

  static String _fmtTimeAgo(DateTime? d) {
    if (d == null) return '—';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(d);
  }
}

/// Small OVERDUE pill shown next to PAID/UNPAID for stale bookings.
class _OverduePill extends StatelessWidget {
  const _OverduePill();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AdminColors.danger,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'OVERDUE',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

/// Gentle opacity pulse on overdue rows so the eye is drawn to them.
class _QueueBlink extends StatefulWidget {
  const _QueueBlink({required this.child});
  final Widget child;
  @override
  State<_QueueBlink> createState() => _QueueBlinkState();
}

class _QueueBlinkState extends State<_QueueBlink>
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
    _opacity = Tween<double>(begin: 1.0, end: 0.6).animate(
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

class _PaidChip extends StatelessWidget {
  const _PaidChip({required this.paid});
  final bool paid;

  @override
  Widget build(BuildContext context) {
    final bg = paid
        ? const Color(0xFFDAF5E0)
        : const Color(0xFFFCE7C2);
    final fg = paid
        ? const Color(0xFF3B7F2A)
        : const Color(0xFFB7791F);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        paid ? 'PAID' : 'UNPAID',
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle_outline,
              size: 56, color: Colors.black26),
          SizedBox(height: 12),
          Text(
            'Inbox zero',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'No bookings waiting for review.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
