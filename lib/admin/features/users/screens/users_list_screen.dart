import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/account_type/domain/account_type.dart';
import '../../../../features/user/domain/user_profile.dart';
import '../../../app/admin_routes.dart';
import '../../../shared/theme/admin_theme.dart';
import '../../../shared/widgets/admin_shell.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(UserProfile u) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    final fields = [
      u.bestDisplayName,
      u.bestOrgLabel,
      u.phone ?? '',
      u.email ?? '',
      u.corporate?.officialEmail ?? '',
      u.individual?.mobile ?? '',
    ].map((s) => s.toLowerCase());
    return fields.any((s) => s.contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminAllUsersProvider);
    return AdminShell(
      section: AdminSection.users,
      title: 'Users',
      subtitle: 'All signed-up customers',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AdminSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Search(
              controller: _search,
              onChanged: (v) =>
                  setState(() => _query = v.trim().toLowerCase()),
            ),
            const SizedBox(height: AdminSpacing.lg),
            async.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(child: Text("Couldn't load users\n$e")),
              ),
              data: (all) {
                final filtered = all.where(_matches).toList()
                  ..sort((a, b) => a.bestDisplayName.compareTo(b.bestDisplayName));
                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        _query.isEmpty
                            ? 'No users yet.'
                            : 'No users match "$_query".',
                        style: AdminText.bodyMedium,
                      ),
                    ),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    color: AdminColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Column(
                    children: [
                      const _Header(),
                      for (final u in filtered) _UserRow(user: u),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Search extends StatelessWidget {
  const _Search({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AdminColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or email',
                hintStyle: AdminText.bodyMedium,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 56),
          Expanded(flex: 4, child: Text('CUSTOMER', style: AdminText.caps)),
          Expanded(flex: 2, child: Text('TYPE', style: AdminText.caps)),
          Expanded(flex: 3, child: Text('CONTACT', style: AdminText.caps)),
          Expanded(flex: 2, child: Text('KYC', style: AdminText.caps)),
          const SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final isCorp = user.corporate != null;
    final contact = (user.corporate?.managerPhone.isNotEmpty == true
            ? user.corporate!.managerPhone
            : user.individual?.mobile ?? user.phone ?? '') ;
    return InkWell(
      onTap: () => context.go(AdminRoutes.userDetailFor(user.uid)),
      hoverColor: AdminColors.hover,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AdminColors.border)),
        ),
        child: Row(
          children: [
            _Avatar(name: user.bestDisplayName, isCorp: isCorp),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.bestDisplayName, style: AdminText.label),
                  if (isCorp && user.corporate!.name.isNotEmpty)
                    Text(user.corporate!.name, style: AdminText.bodySmall),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                isCorp
                    ? 'Corporate'
                    : user.accountType == AccountType.individual
                        ? 'Individual'
                        : '—',
                style: AdminText.bodyMedium,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                contact.isEmpty ? '—' : contact,
                style: AdminText.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(flex: 2, child: _KycPill(status: user.kycStatus)),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.isCorp});
  final String name;
  final bool isCorp;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = (parts.length >= 2
            ? '${parts.first[0]}${parts.last[0]}'
            : (parts.first.isNotEmpty ? parts.first[0] : '?'))
        .toUpperCase();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCorp
              ? const [Color(0xFF378ADD), Color(0xFF185FA5)]
              : const [Color(0xFF7F77DD), Color(0xFF534AB7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _KycPill extends StatelessWidget {
  const _KycPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'verified' => ('Verified', AdminColors.successBg, AdminColors.success),
      'pending' => ('Pending', AdminColors.warningBg, AdminColors.warning),
      'rejected' => ('Rejected', AdminColors.dangerBg, AdminColors.danger),
      _ => ('None', const Color(0xFFEEEEEE), AdminColors.textMuted),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
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
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
