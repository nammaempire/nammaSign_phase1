import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/firebase_providers.dart';

/// Calls the `adminDeleteUser` Cloud Function. The server verifies the
/// caller is in /admins/{uid} before doing anything destructive, so this
/// can safely be exposed to any admin-portal screen.
class AdminDeleteUserRepository {
  AdminDeleteUserRepository({required this._functions});

  final FirebaseFunctions _functions;

  Future<void> deleteUser(String uid) async {
    final callable = _functions.httpsCallable('adminDeleteUser');
    try {
      await callable.call(<String, dynamic>{'uid': uid});
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Delete failed.');
    }
  }
}

final adminDeleteUserRepositoryProvider =
    Provider<AdminDeleteUserRepository>((ref) {
  return AdminDeleteUserRepository(
    functions: ref.watch(cloudFunctionsProvider),
  );
});
