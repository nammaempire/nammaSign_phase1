import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../domain/user_profile.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return FirestoreUserProfileRepository(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

/// Streams `users/{uid}` for the currently signed-in user.
/// Emits null while signed out OR while the doc hasn't been written yet.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(userProfileRepositoryProvider).watch(user.id);
});

/// True when the user has completed setup (picked account type + filled
/// the corporate/individual form). Router uses this to gate new users.
final isSetupCompleteProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider).asData?.value;
  return profile?.isSetupComplete ?? false;
});
