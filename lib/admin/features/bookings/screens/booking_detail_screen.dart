import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/history/domain/booking.dart';
import '../../../../features/history/presentation/providers/bookings_provider.dart';
import '../../../../features/user/domain/user_profile.dart';
import '../../../app/admin_routes.dart';
import '../../../shared/widgets/admin_shell.dart';
import '../../users/providers/admin_user_provider.dart';

class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookingByIdProvider(bookingId));
    return AdminShell(
      section: AdminSection.bookings,
      title: 'Booking',
      actions: [
        TextButton.icon(
          onPressed: () => context.go(AdminRoutes.bookings),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to queue'),
        ),
      ],
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text("Couldn't load booking\n$e")),
        data: (booking) {
          if (booking == null) {
            return const Center(child: Text('Booking not found.'));
          }
          return _DetailBody(booking: booking);
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CustomerCard(userId: booking.userId),
                  const SizedBox(height: 16),
                  _Card(
                    title: 'Campaign',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.campaignTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (booking.description != null &&
                            booking.description!.isNotEmpty)
                          Text(
                            booking.description!,
                            style: const TextStyle(
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Card(
                    title: 'Creative',
                    child: _CreativePreview(booking: booking),
                  ),
                  const SizedBox(height: 16),
                  _Card(
                    title: 'Booking details',
                    child: _LabelRows(rows: [
                      ('Area', '${booking.location} · ${booking.boardType}'),
                      (
                        'Duration',
                        '${booking.durationDays} day'
                            '${booking.durationDays == 1 ? '' : 's'}',
                      ),
                      (
                        'Amount',
                        '₹${NumberFormat.decimalPattern('en_IN').format(booking.amount)}',
                      ),
                      ('Payment method', booking.paymentMethod),
                      (
                        'Submitted',
                        booking.createdAt == null
                            ? '—'
                            : DateFormat('d MMM y · HH:mm')
                                .format(booking.createdAt!),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 320,
              child: _ActionsPanel(booking: booking),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreativePreview extends StatelessWidget {
  const _CreativePreview({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final url = booking.creativeUrl;
    if (url == null || url.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF1EFE8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No creative uploaded.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    if (booking.creativeIsVideo) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1EFE8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.movie_outlined, size: 32, color: Colors.black54),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Video creative. Open in a new tab to review.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            Builder(builder: (ctx) {
              return FilledButton.tonal(
                onPressed: () => _copyUrl(ctx, url),
                child: const Text('Copy video URL'),
              );
            }),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 160,
              alignment: Alignment.center,
              color: const Color(0xFFF1EFE8),
              child: const Text(
                "Couldn't load image.",
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Builder(builder: (ctx) {
          return TextButton.icon(
            onPressed: () => _copyUrl(ctx, url),
            icon: const Icon(Icons.content_copy, size: 16),
            label: const Text('Copy image URL'),
          );
        }),
      ],
    );
  }

  Future<void> _copyUrl(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL copied — paste in a new browser tab.'),
        ),
      );
    }
  }
}

class _ActionsPanel extends ConsumerStatefulWidget {
  const _ActionsPanel({required this.booking});
  final Booking booking;

  @override
  ConsumerState<_ActionsPanel> createState() => _ActionsPanelState();
}

class _ActionsPanelState extends ConsumerState<_ActionsPanel> {
  bool _busy = false;
  String? _message;

  Future<void> _run(Future<void> Function() action, String successMsg) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => _message = successMsg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markPaid() async {
    final ref = await _prompt(
      title: 'Mark as paid',
      label: 'Payment reference (optional)',
    );
    if (ref == null) return; // dismissed
    await _run(
      () => this.ref.read(bookingsRepositoryProvider).adminMarkPaid(
            widget.booking.id,
            paymentRef: ref.isEmpty ? null : ref,
          ),
      'Marked as paid.',
    );
  }

  Future<void> _approve() async {
    if (!widget.booking.paid) {
      setState(() => _message = 'Mark as paid first.');
      return;
    }
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year, now.month, now.day + 1),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1),
      helpText: 'Pick the campaign start date',
    );
    if (picked == null) return;
    final end =
        picked.add(Duration(days: widget.booking.durationDays));
    final reviewer = ref.read(currentUserProvider)?.email ?? 'Admin';
    await _run(
      () => ref.read(bookingsRepositoryProvider).adminApprove(
            widget.booking.id,
            scheduledStartAt: picked,
            scheduledEndAt: end,
            reviewerName: reviewer,
          ),
      'Approved.',
    );
  }

  Future<void> _reject() async {
    final result = await showDialog<_RejectInput>(
      context: context,
      builder: (_) => const _RejectDialog(),
    );
    if (result == null) return;
    final reviewer = ref.read(currentUserProvider)?.email ?? 'Admin';
    await _run(
      () => ref.read(bookingsRepositoryProvider).adminReject(
            widget.booking.id,
            reason: result.reason,
            ruleCode: result.ruleCode,
            reviewerName: reviewer,
          ),
      'Rejected.',
    );
  }

  Future<String?> _prompt({required String title, required String label}) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return _Card(
      title: 'Actions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                booking.paid
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: booking.paid ? Colors.green : Colors.black38,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                booking.paid ? 'Paid' : 'Awaiting payment',
                style: TextStyle(
                  color: booking.paid ? Colors.green[800] : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _busy || booking.paid ? null : _markPaid,
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Mark as paid'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy || !booking.paid ? null : _approve,
            icon: const Icon(Icons.check),
            label: const Text('Approve & schedule'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _reject,
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text(
              'Reject',
              style: TextStyle(color: Colors.red),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}

class _RejectInput {
  const _RejectInput({required this.reason, this.ruleCode});
  final String reason;
  final String? ruleCode;
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();
  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reason = TextEditingController();
  final _rule = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    _rule.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject booking'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _reason,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Reason (shown to the customer)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rule,
              decoration: const InputDecoration(
                labelText: 'Rule code (optional, e.g. NE-CREATIVE-04)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            final r = _reason.text.trim();
            if (r.isEmpty) return;
            Navigator.of(context).pop(_RejectInput(
              reason: r,
              ruleCode: _rule.text.trim().isEmpty ? null : _rule.text.trim(),
            ));
          },
          child: const Text('Reject'),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Customer summary card — streams the user profile at users/{userId} and
/// shows the human-friendly identity bits the admin needs at a glance.
class _CustomerCard extends ConsumerWidget {
  const _CustomerCard({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminUserProfileProvider(userId));
    return _Card(
      title: 'Customer',
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (e, _) => Text(
          "Couldn't load customer: $e",
          style: const TextStyle(color: Colors.red),
        ),
        data: (profile) => _CustomerBody(userId: userId, profile: profile),
      ),
    );
  }
}

class _CustomerBody extends StatelessWidget {
  const _CustomerBody({required this.userId, required this.profile});
  final String userId;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return Text(
        'No profile on file (uid $userId).',
        style: const TextStyle(color: Colors.black54),
      );
    }
    final corp = profile!.corporate;
    final individual = profile!.individual;

    // Pick the best identity fields based on account type.
    final isCorp = corp != null;
    final headline =
        (isCorp ? corp!.name : individual?.fullName) ?? '(no name)';
    final subline = isCorp ? 'Corporate' : 'Individual';
    final phone =
        (isCorp ? corp!.managerPhone : individual?.mobile) ?? '';
    final email = isCorp ? corp!.officialEmail : null;
    final managerName = isCorp ? corp!.managerName : null;
    final kyc = profile!.kycStatus ?? 'none';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isCorp
                    ? const Color(0xFFE6F1FB)
                    : const Color(0xFFEEEDFE),
                borderRadius: BorderRadius.circular(22),
              ),
              alignment: Alignment.center,
              child: Icon(
                isCorp
                    ? Icons.apartment_outlined
                    : Icons.person_outline_rounded,
                color: isCorp
                    ? const Color(0xFF185FA5)
                    : const Color(0xFF534AB7),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subline,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            _KycChip(status: kyc),
          ],
        ),
        const SizedBox(height: 16),
        _LabelRows(rows: [
          if (managerName != null && managerName.isNotEmpty)
            ('Manager', managerName),
          if (phone.isNotEmpty) ('Phone', phone),
          if (email != null && email.isNotEmpty) ('Email', email),
          if (isCorp && corp!.panCin.isNotEmpty) ('PAN / CIN', corp.panCin),
          if (!isCorp && (individual?.aadhaarLast4.isNotEmpty ?? false))
            ('Aadhaar (last 4)', 'XXXX XXXX ${individual!.aadhaarLast4}'),
          ('User id', userId),
        ]),
      ],
    );
  }
}

class _KycChip extends StatelessWidget {
  const _KycChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'verified' => (
          'KYC VERIFIED',
          const Color(0xFFDAF5E0),
          const Color(0xFF3B7F2A),
        ),
      'pending' => (
          'KYC PENDING',
          const Color(0xFFFCE7C2),
          const Color(0xFFB7791F),
        ),
      'rejected' => (
          'KYC REJECTED',
          const Color(0xFFF4DCDF),
          const Color(0xFFB7245B),
        ),
      _ => (
          'NO KYC',
          const Color(0xFFEEEEEE),
          const Color(0xFF6E6E7C),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
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

class _LabelRows extends StatelessWidget {
  const _LabelRows({required this.rows});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final r in rows) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    r.$1,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                Expanded(
                  child: Text(
                    r.$2,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
