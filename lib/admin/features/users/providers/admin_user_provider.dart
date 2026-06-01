import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/user/domain/user_profile.dart';
import '../../../../features/user/presentation/providers/user_profile_provider.dart';

/// Streams the profile at `users/{uid}` for any uid — used by admin screens
/// to look up customer details on a booking. Firestore rules allow admins
/// to read any user doc.
final adminUserProfileProvider =
    StreamProvider.family<UserProfile?, String>((ref, uid) {
  if (uid.isEmpty) return Stream.value(null);
  return ref.watch(userProfileRepositoryProvider).watch(uid);
});
