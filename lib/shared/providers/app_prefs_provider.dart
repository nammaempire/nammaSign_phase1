import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

/// Loads SharedPreferences once on app start and exposes typed accessors.
/// Used by the router to avoid hitting prefs on every navigation.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((_) {
  return SharedPreferences.getInstance();
});

/// Whether prefs have finished loading. Router uses this to know if it's
/// safe to read prefs-derived providers.
final prefsReadyProvider = Provider<bool>((ref) {
  return ref.watch(sharedPreferencesProvider).hasValue;
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
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(StorageKeys.onboardingComplete, true);
    if (accountType != null) {
      await prefs.setString(StorageKeys.accountType, accountType);
    }
    state = true;
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
