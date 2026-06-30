import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/user/presentation/providers/user_profile_provider.dart';
import 'analytics_service.dart';

/// Spawn-once provider that wires the signed-in user's id into both
/// Analytics and Crashlytics, and the user's account type into a slicing
/// property.
///
/// Watch this once from `App` (alongside `fcmBootstrapProvider`). When the
/// auth user changes, this provider re-runs its listener and updates the
/// downstream identity automatically.
class AnalyticsIdentityBootstrap {
  AnalyticsIdentityBootstrap(this._ref) {
    _init();
  }

  final Ref _ref;

  void _init() {
    // Tag every dropped crash with the signed-in uid so Crashlytics
    // groups + filters by user. Also fire login / logout events into
    // Analytics on the same transition.
    _ref.listen(currentUserProvider, (prev, next) async {
      final analytics = _ref.read(analyticsServiceProvider);
      final crashlytics = FirebaseCrashlytics.instance;

      final wasSignedIn = prev != null;
      final isSignedIn = next != null;

      if (!isSignedIn) {
        if (wasSignedIn) await analytics.signedOut();
        await analytics.setUserId(null);
        await crashlytics.setUserIdentifier('');
      } else {
        await analytics.setUserId(next.id);
        await crashlytics.setUserIdentifier(next.id);
        if (!wasSignedIn) {
          // We don't know here whether it's a brand new account vs a
          // returning user. We log sign_in_completed; signUpCompleted
          // gets fired explicitly from the signup screens once the
          // profile is saved.
          await analytics.signInCompleted(method: 'phone_or_google');
        }
      }
    }, fireImmediately: true);

    // Tag the account_type user property once the Firestore profile
    // resolves. Useful for slicing funnels (corporate vs individual).
    _ref.listen(userProfileProvider, (prev, next) async {
      final profile = next.asData?.value;
      if (profile == null) return;
      final type = profile.accountType?.name;
      if (type != null) {
        await _ref.read(analyticsServiceProvider).setAccountType(type);
      }
      await _ref
          .read(analyticsServiceProvider)
          .setKycStatus(profile.kycStatus);
    });
  }
}

final analyticsIdentityBootstrapProvider =
    Provider<AnalyticsIdentityBootstrap>(
  (ref) => AnalyticsIdentityBootstrap(ref),
);
