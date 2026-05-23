/// Single source of truth for route paths.
/// Reference these instead of hardcoding strings in `context.go(...)` calls.
class AppRoutes {
  AppRoutes._();

  // Top-level
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String accountType = '/account-type';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String signupCorporate = '/signup/corporate';
  static const String signupIndividual = '/signup/individual';

  // Booking flow
  static const String bookingSelectType = '/booking/select-type';
  static const String bookingCorporate = '/booking/corporate-campaign';
  static const String bookingIndividual = '/booking/individual-campaign';
  static const String bookingReview = '/booking/review';
  static const String bookingSuccess = '/booking/success';
  static const String bookingFailure = '/booking/failure';

  // Campaign status (after admin review). Pass `bookingId` as a path param.
  static const String campaignStatus = '/campaign/:bookingId';
  static String campaignStatusFor(String id) => '/campaign/$id';

  /// AccountTypeScreen reads this query param to decide where Continue
  /// goes: `onboarding` → /login, `signup` → /signup/{type}.
  static const String accountTypeModeParam = 'mode';
  static const String accountTypeModeOnboarding = 'onboarding';
  static const String accountTypeModeSignup = 'signup';

  // Main shell tabs
  static const String home = '/home';
  static const String history = '/history';
  static const String profile = '/profile';
}
