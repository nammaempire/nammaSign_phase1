import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

/// Loads SharedPreferences once on app start and exposes typed accessors.
/// Used by the router to avoid hitting prefs on every navigation.
///
/// Guarded with a timeout: on some emulators/devices the platform call can
/// hang indefinitely, which would trap the app on the splash screen forever
/// (the router blocks on [prefsReadyProvider]). If it doesn't resolve in
/// time we surface the error so the router can proceed with safe defaults
/// (onboarding treated as not-yet-seen).
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((_) async {
  try {
    return await SharedPreferences.getInstance()
        .timeout(const Duration(seconds: 4));
  } catch (e, st) {
    appLogger.e(
      'SharedPreferences.getInstance() failed or timed out',
      error: e,
      stackTrace: st,
    );
    rethrow;
  }
});

/// Whether prefs have finished resolving — either with a value OR an error.
/// The router only needs to know it's no longer pending so it can stop
/// holding the user on the splash screen.
final prefsReadyProvider = Provider<bool>((ref) {
  return !ref.watch(sharedPreferencesProvider).isLoading;
});

/// Whether the user has completed first-launch onboarding (i.e. picked
/// an account type and tapped Continue).
///
/// Implemented as a [Notifier] rather than a plain `Provider<bool>` so that
/// callers can flip the flag in one synchronous operation
/// (`markComplete()`) — that way the router redirect sees the new value
/// immediately, instead of being stuck on the cached `false` from app start.
class OnboardingSeenNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).maybeWhen(
          data: (prefs) =>
              prefs.getBool(StorageKeys.onboardingComplete) ?? false,
          orElse: () => false,
        );
  }

  /// Marks onboarding complete. Persists to prefs and updates in-memory
  /// state in the same call so the router redirect picks it up on the next
  /// navigation.
  ///
  /// Optionally also persists the chosen account type in the same write so
  /// callers don't need two await-trips through SharedPreferences.
  Future<void> markComplete({String? accountType}) async {
    // Flip the in-memory flag FIRST so the router navigates immediately,
    // even if the prefs platform call is slow or hangs (it must never block
    // the user from leaving onboarding). Persistence below is best-effort.
    state = true;
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      await prefs.setBool(StorageKeys.onboardingComplete, true);
      if (accountType != null) {
        await prefs.setString(StorageKeys.accountType, accountType);
      }
    } catch (e, st) {
      appLogger.w(
        'Could not persist onboarding flag (continuing anyway)',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Resets the flag (debug / "Start over" actions).
  Future<void> reset() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.remove(StorageKeys.onboardingComplete);
    await prefs.remove(StorageKeys.accountType);
    state = false;
  }
}

final onboardingSeenProvider =
    NotifierProvider<OnboardingSeenNotifier, bool>(
  OnboardingSeenNotifier.new,
);
