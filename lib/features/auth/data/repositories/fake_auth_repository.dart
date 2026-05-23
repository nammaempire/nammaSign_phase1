import 'dart:async';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// In-memory implementation of [AuthRepository] used during the UI-only phase.
///
/// Simulates the real OTP flow without hitting Firebase:
///   - sendOtp succeeds after a 600ms delay and returns a stub verificationId.
///   - verifyOtp accepts the code `123456` (or any 6-digit code in dev mode),
///     anything else throws.
///   - sign-in/sign-up always succeed.
///
/// Swap this for the Firebase implementation in Phase 1b by replacing the
/// binding in `authRepositoryProvider`.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository();

  /// Accept any 6-digit code in dev. Set to e.g. '123456' to enforce.
  static const String? _expectedCode = null;
  static const String _fakeVerificationId = 'fake-verification-id';

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> authStateChanges() {
    // Emit current value on subscribe.
    return Stream<AppUser?>.value(_current).asyncExpand((value) async* {
      yield value;
      yield* _controller.stream;
    });
  }

  @override
  Future<String> sendOtp(String phoneNumber) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return _fakeVerificationId;
  }

  @override
  Future<AppUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (smsCode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(smsCode)) {
      throw const AuthException('Enter a valid 6-digit code');
    }
    if (_expectedCode != null && smsCode != _expectedCode) {
      throw const AuthException('Invalid code');
    }
    final user = UserModel(
      id: 'fake-user-id',
      phone: '+91 ${verificationId.hashCode.abs() % 9000000000 + 1000000000}',
      displayName: 'Demo User',
      createdAt: DateTime.now(),
    );
    _current = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final user = UserModel(
      id: 'fake-user-id',
      email: email,
      displayName: email.split('@').first,
      createdAt: DateTime.now(),
    );
    _current = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  }) =>
      signInWithEmail(email: email, password: password);

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _current = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();
}
