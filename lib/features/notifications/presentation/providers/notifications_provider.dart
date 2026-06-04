import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/notifications_repository.dart';
import '../../domain/app_notification.dart';

/// Live notifications for the currently signed-in user. Resets cleanly to
/// an empty list when signed out, so consumers never have to null-check.
final notificationsStreamProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(notificationsRepositoryProvider).watchAll(user.id);
});

/// Number of unread notifications — drives the badge on the bell icon.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsStreamProvider);
  final list = async.asData?.value ?? const [];
  return list.where((n) => !n.read).length;
});
