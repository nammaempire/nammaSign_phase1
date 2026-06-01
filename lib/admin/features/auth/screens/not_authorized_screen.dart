import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';

class NotAuthorizedScreen extends ConsumerWidget {
  const NotAuthorizedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 56, color: Colors.black54),
                const SizedBox(height: 16),
                const Text(
                  'Not authorized',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This account does not have admin privileges. Ask the owner '
                  'to add a document at admins/{your-uid} in Firestore.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                  },
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
