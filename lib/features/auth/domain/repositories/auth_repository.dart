import '../entities/app_user.dart';

/// Abstract auth contract. The presentation layer depends on this, not on
/// Firebase. Swap the implementation freely (mocks for tests, alt provider).
abstract class AuthRepository {
  /// Currently signed-in user, or null.
  Stream<AppUser?> authStateChanges();

  /// Returns the current user synchronously (may be null).
  AppUser? get currentUser;

  /// Sends an OTP to [phoneNumber] (E.164 e.g. +911234567890).
  /// Returns the verificationId needed to confirm the OTP.
  Future<String> sendOtp(String phoneNumber);

  /// Confirms the OTP using the verificationId from [sendOtp].
  Future<AppUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  });

  /// Email + password sign-in (optional secondary path).
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Google Sign-In. Opens the platform Google account picker, exchanges
  /// the resulting idToken for a Firebase credential, and returns the
  /// signed-in user. Throws [AuthException] with code `'cancelled'` if
  /// the user dismisses the picker.
  Future<AppUser> signInWithGoogle();

  Future<void> signOut();
}
