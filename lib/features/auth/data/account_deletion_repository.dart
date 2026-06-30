import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/firebase_providers.dart';

/// Thin wrapper around the `deleteMyAccount` Cloud Function. Centralised
/// here so the call site (a destructive button in Profile) stays compact
/// and any error transforming happens in one place.
class AccountDeletionRepository {
  AccountDeletionRepository({required this._functions});

  final FirebaseFunctions _functions;

  /// Server-side hard-delete of the current user's account. Cancels their
  /// active bookings, wipes their Firestore data + Storage files, then
  /// removes the Firebase Auth user. After this completes the local Auth
  /// stream emits `null` and the router carries the user to /login.
  Future<void> deleteMyAccount() async {
    final callable = _functions.httpsCallable('deleteMyAccount');
    try {
      await callable.call();
    } on FirebaseFunctionsException catch (e) {
      // Surface the message verbatim so the UI snackbar shows something
      // useful (e.g. "unauthenticated", "internal").
      throw Exception(e.message ?? 'Account deletion failed.');
    }
  }
}

final accountDeletionRepositoryProvider =
    Provider<AccountDeletionRepository>((ref) {
  return AccountDeletionRepository(
    functions: ref.watch(cloudFunctionsProvider),
  );
});
