import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../features/account_type/domain/account_type.dart';
import '../../../../features/history/domain/booking.dart';
import '../../../../features/history/presentation/providers/bookings_provider.dart';
import '../../../../features/user/domain/user_profile.dart';
import '../../../../features/user/presentation/providers/user_profile_provider.dart';
import '../data/admin_delete_user_repository.dart';
import '../../../app/admin_routes.dart';
import '../../../shared/theme/admin_theme.dart';
import '../../../shared/widgets/admin_shell.dart';
import '../providers/admin_user_provider.dart';

class UserDetailScreen extends ConsumerWidget {
  const UserDetailScreen({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminUserProfileProvider(uid));
    return AdminShell(
      section: AdminSection.users,
      title: 'Customer',
      actions: [
        TextButton.icon(
          onPressed: () => context.go(AdminRoutes.users),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Back to users'),
        ),
      ],
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Couldn't load: $e")),
        data: (u) {
          if (u == null) return const Center(child: Text('User not found.'));
          return _Body(user: u);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminSpacing.xxl),
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
                  _ProfileHero(user: user),
                  const SizedBox(height: 16),
                  _KycCard(user: user),
                  const SizedBox(height: 16),
                  _BookingsCard(uid: user.uid),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(width: 320, child: _ActionsPanel(user: user)),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final isCorp = user.corporate != null;
    final subtitle = isCorp
        ? user.corporate!.name
        : (user.accountType == AccountType.individual
            ? 'Individual'
            : 'Setup incomplete');
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AdminColors.primary, AdminColors.primaryDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(user.bestDisplayName),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.bestDisplayName,
                  style: AdminText.h1.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
                Text(
                  subtitle,
                  style: AdminText.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return (parts.length >= 2
            ? '${parts.first[0]}${parts.last[0]}'
            : (parts.first.isNotEmpty ? parts.first[0] : '?'))
        .toUpperCase();
  }
}

class _KycCard extends StatelessWidget {
  const _KycCard({required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final docs = user.kycDocs;
    return _SectionCard(
      title: 'KYC Documents',
      child: docs.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No documents uploaded.',
                style: AdminText.bodyMedium,
              ),
            )
          : Column(
              children: [
                for (final entry in docs.entries)
                  _DocRow(label: entry.key, url: entry.value),
              ],
            ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({required this.label, required this.url});
  final String label;
  final String url;

  String get _displayLabel {
    switch (label) {
      case 'aadhaarFront':
        return 'Aadhaar — Front';
      case 'aadhaarBack':
        return 'Aadhaar — Back';
      case 'panCin':
        return 'PAN / CIN';
      case 'additional':
        return 'Additional document';
      default:
        return label;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AdminColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.description_outlined,
              color: AdminColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_displayLabel, style: AdminText.label),
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('URL copied — paste in a new tab.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.content_copy, size: 16),
            label: const Text('Copy URL'),
          ),
        ],
      ),
    );
  }
}

class _BookingsCard extends ConsumerWidget {
  const _BookingsCard({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_userBookingsProvider(uid));
    return _SectionCard(
      title: 'Recent bookings',
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (e, _) => Text("Couldn't load: $e"),
        data: (list) {
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No bookings yet.',
                style: AdminText.bodyMedium,
              ),
            );
          }
          return Column(
            children: [
              for (final b in list.take(6))
                InkWell(
                  onTap: () =>
                      context.go(AdminRoutes.bookingDetailFor(b.id)),
                  hoverColor: AdminColors.hover,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AdminColors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: b.status.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 4,
                          child: Text(
                            b.campaignTitle,
                            style: AdminText.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            b.status.label,
                            style: AdminText.caps.copyWith(
                              color: b.status.accent,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₹${NumberFormat.decimalPattern('en_IN').format(b.amount)}',
                            style: AdminText.label,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AdminColors.textMuted,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Provider for a specific user's booking history (admin view).
final _userBookingsProvider =
    StreamProvider.family<List<Booking>, String>((ref, uid) {
  return ref.watch(bookingsRepositoryProvider).watchForUser(uid);
});

class _ActionsPanel extends ConsumerStatefulWidget {
  const _ActionsPanel({required this.user});
  final UserProfile user;

  @override
  ConsumerState<_ActionsPanel> createState() => _ActionsPanelState();
}

class _ActionsPanelState extends ConsumerState<_ActionsPanel> {
  bool _busy = false;
  String? _message;

  Future<void> _set(String status) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref
          .read(userProfileRepositoryProvider)
          .adminSetKycStatus(widget.user.uid, status);
      if (!mounted) return;
      setState(() => _message = 'KYC set to $status.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final phone =
        u.corporate?.managerPhone ?? u.individual?.mobile ?? u.phone ?? '';
    final email = u.corporate?.officialEmail ?? u.email ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Contact',
          child: _LabelRows(rows: [
            if (phone.isNotEmpty) ('Phone', phone),
            if (email.isNotEmpty) ('Email', email),
            if (u.corporate != null) ('PAN / CIN', u.corporate!.panCin),
            if (u.individual != null &&
                u.individual!.aadhaarLast4.isNotEmpty)
              ('Aadhaar', 'XXXX XXXX ${u.individual!.aadhaarLast4}'),
            ('User id', u.uid),
          ]),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'KYC actions',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed:
                    _busy || u.kycStatus == 'verified' ? null : () => _set('verified'),
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Mark KYC verified'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed:
                    _busy || u.kycStatus == 'rejected' ? null : () => _set('rejected'),
                icon: const Icon(Icons.cancel_outlined, color: AdminColors.danger),
                label: const Text(
                  'Reject KYC',
                  style: TextStyle(color: AdminColors.danger),
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(_message!, style: AdminText.bodyMedium),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DangerZone(user: u),
      ],
    );
  }
}

/// Hard-delete the customer's account. Lives in a separate card with a
/// red outline so it's visually quarantined from the routine KYC actions
/// above. Requires the admin to type the customer's email to confirm.
class _DangerZone extends ConsumerWidget {
  const _DangerZone({required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      decoration: BoxDecoration(
        color: AdminColors.dangerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.danger),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'DANGER ZONE',
            style: AdminText.caps.copyWith(color: AdminColors.danger),
          ),
          const SizedBox(height: 8),
          Text(
            'Hard-deletes the account, KYC docs, bookings, and FCM tokens.'
            " The user can sign back in with the same phone, but they'll"
            ' come back as a brand-new account with no history.',
            style: AdminText.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.danger,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_forever_outlined, size: 18),
            label: const Text('Delete account'),
            onPressed: () => _confirmAdminDelete(context, ref, user),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmAdminDelete(
  BuildContext context,
  WidgetRef ref,
  UserProfile user,
) async {
  // We confirm using whichever stable identifier we have — email if the
  // user has one, otherwise phone number. That way the admin types in
  // something they can verify on the customer card on the left.
  final expected = user.email?.isNotEmpty == true
      ? user.email!
      : (user.phone ?? user.uid);
  final identifierKind = user.email?.isNotEmpty == true
      ? 'email'
      : (user.phone?.isNotEmpty == true ? 'phone number' : 'user id');

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AdminDeleteDialog(
      expected: expected,
      identifierKind: identifierKind,
      displayName: user.bestDisplayName,
    ),
  );
  if (confirmed != true) return;
  if (!context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Deleting account…'),
        ],
      ),
    ),
  );

  try {
    await ref
        .read(adminDeleteUserRepositoryProvider)
        .deleteUser(user.uid);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss progress
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user.bestDisplayName} deleted.')),
    );
    // Pop back to the users list since the detail page is now stale.
    context.go(AdminRoutes.users);
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Couldn't delete user"),
        content: Text('$e'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _AdminDeleteDialog extends StatefulWidget {
  const _AdminDeleteDialog({
    required this.expected,
    required this.identifierKind,
    required this.displayName,
  });

  final String expected;
  final String identifierKind;
  final String displayName;

  @override
  State<_AdminDeleteDialog> createState() => _AdminDeleteDialogState();
}

class _AdminDeleteDialogState extends State<_AdminDeleteDialog> {
  final _ctrl = TextEditingController();
  bool get _canConfirm =>
      _ctrl.text.trim().toLowerCase() == widget.expected.trim().toLowerCase();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.warning_amber_rounded,
        size: 36,
        color: AdminColors.danger,
      ),
      title: const Text('Delete this account?'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You're about to permanently delete "
              '${widget.displayName}\'s account. Their profile, KYC '
              'documents, notifications, and FCM tokens will be removed. '
              'Active bookings will be cancelled.',
              style: AdminText.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Type the customer\'s ${widget.identifierKind} to confirm:',
              style: AdminText.bodySmall,
            ),
            const SizedBox(height: 4),
            SelectableText(
              widget.expected,
              style: AdminText.label,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.expected,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AdminColors.danger),
          onPressed:
              _canConfirm ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Delete forever'),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: AdminText.caps),
          const SizedBox(height: 12),
          child,
        ],
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
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  child: Text(r.$1, style: AdminText.bodySmall),
                ),
                Expanded(
                  child: Text(
                    r.$2,
                    style: AdminText.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
