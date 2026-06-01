import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/providers/firebase_providers.dart';

/// Streams whether the currently signed-in user has admin privileges.
///
/// Admins are represented by a doc at `admins/{uid}` (top-level collection).
/// The firestore.rules `isAdmin()` helper checks the same path. To grant
/// yourself admin access, create the doc once in the Firebase Console.
final isAdminProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(false);
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('admins')
      .doc(user.id)
      .snapshots()
      .map((snap) => snap.exists);
});
