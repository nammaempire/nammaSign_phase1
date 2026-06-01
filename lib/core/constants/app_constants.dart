/// Global app-wide constants. Avoid magic strings; centralize here.
class AppConstants {
  AppConstants._();

  static const String appName = 'NammaSign';
  static const String appBrandSubtitle = 'AD-TECH MARKETPLACE';
  static const String appTagline = 'Own the streets. Light up the city.';
  static const String appVersionLabel = 'V5.0';
  static const String appOriginLabel = 'MADE IN INDIA';
  static const Duration splashDuration = Duration(seconds: 3);

  /// Logo assets. Drop your actual PNGs (transparent background preferred)
  /// at these paths under `assets/icons/`.
  /// - logoLockup: full lockup with mark + "NAMMASIGN" + tagline.
  /// - logoMark: just the geometric NS mark, no text. Used in small spaces
  ///   like the app bar and the login card.
  static const String logoLockup = 'assets/icons/nammasign_logo.png';
  static const String logoMark = 'assets/icons/nammasign_mark.png';

  // Animation durations
  static const Duration shortAnim = Duration(milliseconds: 200);
  static const Duration mediumAnim = Duration(milliseconds: 350);
  static const Duration longAnim = Duration(milliseconds: 600);

  // Pagination
  static const int defaultPageSize = 20;

  // Validation
  static const int otpLength = 6;
  static const int phoneLength = 10;
}

/// Firestore collection names. One source of truth — change here only.
class FirestoreCollections {
  FirestoreCollections._();

  static const String users = 'users';
  static const String areas = 'areas';        // 3 area listings
  static const String devices = 'devices';    // 12 signage boards
  static const String bookings = 'bookings';
  static const String payments = 'payments';
  static const String waitlist = 'waitlist';
  static const String config = 'config';

  // Subcollections (used relative to parent)
  static const String notifications = 'notifications';
  static const String kycDocs = 'kycDocs';
  static const String scheduleItems = 'scheduleItems';
}

/// SharedPreferences keys.
class StorageKeys {
  StorageKeys._();

  static const String onboardingComplete = 'onboarding_complete';
  static const String themeMode = 'theme_mode';
  static const String locale = 'locale';
  static const String accountType = 'account_type';
}
