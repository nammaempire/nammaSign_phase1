import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/firebase_providers.dart';

/// Strongly-typed wrapper around [FirebaseAnalytics].
///
/// Every product event the app fires goes through one of the methods
/// below so we can't typo an event name in a call site and lose six
/// months of funnel data. Add a new method here, then call it from the
/// feature code — never call `_a.logEvent` directly from a screen.
///
/// Conventions:
///   - event names are snake_case (Firebase requirement)
///   - all params are simple types (String / int / bool)
///   - never pass PII (no phone, email, name) — Firebase strips PII
///     automatically but be explicit anyway
class AnalyticsService {
  AnalyticsService(this._a);
  final FirebaseAnalytics _a;

  // ---------------------------------------------------------------------------
  // Identity / session
  // ---------------------------------------------------------------------------

  /// Tags the analytics session with a user id once they sign in. Firebase
  /// hashes the value before storing — it's still PII so we never log raw
  /// phone numbers or emails through here.
  Future<void> setUserId(String? uid) => _a.setUserId(id: uid);

  /// One-time tag for slicing reports — Corporate vs Individual funnels.
  Future<void> setAccountType(String accountType) =>
      _a.setUserProperty(name: 'account_type', value: accountType);

  Future<void> setKycStatus(String status) =>
      _a.setUserProperty(name: 'kyc_status', value: status);

  // ---------------------------------------------------------------------------
  // Auth funnel
  // ---------------------------------------------------------------------------

  Future<void> signInStarted({required String method}) {
    return _a.logEvent(name: 'sign_in_started', parameters: {'method': method});
  }

  Future<void> signInCompleted({required String method}) {
    return _a.logLogin(loginMethod: method);
  }

  Future<void> signUpCompleted({required String accountType}) {
    return _a.logSignUp(signUpMethod: accountType);
  }

  Future<void> signedOut() => _a.logEvent(name: 'sign_out');

  Future<void> accountDeleted() => _a.logEvent(name: 'account_deleted');

  // ---------------------------------------------------------------------------
  // KYC
  // ---------------------------------------------------------------------------

  Future<void> kycUploaded({required String docKind}) {
    return _a.logEvent(
      name: 'kyc_uploaded',
      parameters: {'doc_kind': docKind},
    );
  }

  // ---------------------------------------------------------------------------
  // Marketplace + booking funnel
  // ---------------------------------------------------------------------------

  Future<void> listingViewed({required String areaId}) {
    return _a.logEvent(
      name: 'listing_viewed',
      parameters: {'area_id': areaId},
    );
  }

  Future<void> bookingStarted({required String areaId}) {
    return _a.logEvent(
      name: 'booking_started',
      parameters: {'area_id': areaId},
    );
  }

  Future<void> bookingSubmitted({
    required String areaId,
    required int durationDays,
    required int amountRupees,
    required String accountType,
  }) {
    return _a.logEvent(
      name: 'booking_submitted',
      parameters: {
        'area_id': areaId,
        'duration_days': durationDays,
        'value': amountRupees,
        'currency': 'INR',
        'account_type': accountType,
      },
    );
  }

  /// Fired when a campaign hits LIVE (admin approval). This is more useful
  /// than booking_submitted for measuring real conversion since not every
  /// submission gets approved.
  Future<void> campaignWentLive({
    required String areaId,
    required int amountRupees,
  }) {
    return _a.logEvent(
      name: 'campaign_went_live',
      parameters: {
        'area_id': areaId,
        'value': amountRupees,
        'currency': 'INR',
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Notifications + misc
  // ---------------------------------------------------------------------------

  Future<void> notificationTapped({required String type}) {
    return _a.logEvent(
      name: 'notification_tapped',
      parameters: {'type': type},
    );
  }

  Future<void> invoiceDownloaded() => _a.logEvent(name: 'invoice_downloaded');

  Future<void> appBookingShared() => _a.logEvent(name: 'booking_shared');

  Future<void> screenView({required String name}) =>
      _a.logScreenView(screenName: name);

  // ---------------------------------------------------------------------------
  // Escape hatch
  // ---------------------------------------------------------------------------

  /// Use sparingly when adding a new event mid-experiment. Promote to a
  /// real typed method here once the event stabilises.
  Future<void> custom(String name, [Map<String, Object>? params]) {
    if (kDebugMode && !RegExp(r'^[a-z][a-z0-9_]{0,39}$').hasMatch(name)) {
      assert(false, "Analytics event name '$name' isn't snake_case "
          'or is too long (40 char max).');
    }
    return _a.logEvent(name: name, parameters: params);
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(ref.watch(firebaseAnalyticsProvider));
});
