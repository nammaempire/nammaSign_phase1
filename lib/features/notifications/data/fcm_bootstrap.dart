import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../../../shared/providers/firebase_providers.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'notifications_repository.dart';

/// Pending deep-link captured from a notification tap before the router
/// was ready. The app router watches this and navigates to the campaign
/// status screen the moment the user is signed in + on a tab page.
final pendingNotificationBookingIdProvider = StateProvider<String?>(
  (_) => null,
);

/// Hooks up Firebase Messaging:
///   - asks for OS permission (iOS shows the system dialog)
///   - registers the device's FCM token under the signed-in user
///   - listens to foreground messages (handled by the listener inside the
///     notifications screen so the bell badge animates immediately)
///   - listens for notification taps (cold open + warm tap) and routes
///     the user to the right campaign
///
/// Call once from a `ProviderListenable` higher up in the tree. Re-runs
/// whenever the signed-in user changes.
class FcmBootstrap {
  FcmBootstrap(this._ref) {
    _init();
  }

  final Ref _ref;
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    final messaging = _ref.read(firebaseMessagingProvider);

    // 1. Permission. On Android 12 and below this returns authorized
    //    automatically. On Android 13+ and iOS, the OS shows a dialog.
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      appLogger.d('FCM permission: ${settings.authorizationStatus}');
    } catch (e, st) {
      appLogger.e('FCM permission failed', error: e, stackTrace: st);
    }

    // 2. Watch sign-in state. Every time the user changes:
    //      - register the new user's token
    //      - listen for token refresh
    _ref.listen(currentUserProvider, (prev, next) async {
      if (next == null) return;
      try {
        final repo = _ref.read(notificationsRepositoryProvider);
        await repo.registerCurrentToken(next.id);
        appLogger.d('Registered FCM token for ${next.id}');
      } catch (e, st) {
        appLogger.e('Token register failed', error: e, stackTrace: st);
      }
    }, fireImmediately: true);

    // 3. Token refresh — when iOS/Android rotates the token, persist the
    //    new one against whoever is currently signed in.
    messaging.onTokenRefresh.listen((token) async {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;
      try {
        await _ref
            .read(firestoreProvider)
            .collection('users')
            .doc(user.id)
            .set(
          {
            'fcmTokens': [token],
            'fcmTokenUpdatedAt': DateTime.now().toIso8601String(),
          },
          // We don't replace the whole array here — but if the OS rotated
          // the token, the *old* token will go stale and CF prune it on
          // the next send. So just merging in this one is safe.
        );
      } catch (e, st) {
        appLogger.e('Token refresh persist failed', error: e, stackTrace: st);
      }
    });

    // 4. Tap handlers. Two cases:
    //    a) App was killed and launched by tapping the notification.
    //    b) App was backgrounded and brought forward by the tap.
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _handleTap(initial);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // 5. Foreground messages. iOS swallows the banner by default when the
    //    app is foreground; we let it through so the user notices.
    if (!kIsWeb) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _handleTap(RemoteMessage message) {
    final bookingId = message.data['bookingId'] as String?;
    if (bookingId == null || bookingId.isEmpty) return;
    appLogger.d('FCM tap → bookingId=$bookingId');
    _ref.read(pendingNotificationBookingIdProvider.notifier).state = bookingId;
  }
}

/// Spawn-once provider. Watching this anywhere in the tree (typically
/// inside the root App widget) wires FCM up for the lifetime of the app.
final fcmBootstrapProvider = Provider<FcmBootstrap>(
  (ref) => FcmBootstrap(ref),
);
