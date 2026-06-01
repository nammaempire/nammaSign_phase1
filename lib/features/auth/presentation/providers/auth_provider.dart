import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../data/repositories/fake_auth_repository.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Set to `true` to use the in-memory [FakeAuthRepository] (UI dev mode —
/// any 6-digit OTP works, no network calls). Set to `false` for the real
/// Firebase Auth backed implementation.
///
/// Production / staging builds must keep this false. We leave the toggle
/// in place so widget tests + early UI iteration don't require Firebase
/// to be initialised.
const bool _useFakeAuth = false;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (_useFakeAuth) {
    final repo = FakeAuthRepository();
    ref.onDispose(repo.dispose);
    return repo;
  }

  return FirebaseAuthRepository(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

/// Reactive stream of the currently signed-in user (or null).
/// Used by the router to redirect between auth and main shell.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Synchronous accessor — convenient for one-off reads.
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).asData?.value;
});

// ---------------------------------------------------------------------------
// OTP flow state machine
// ---------------------------------------------------------------------------

sealed class OtpFlowState {
  const OtpFlowState();
}

class OtpIdle extends OtpFlowState {
  const OtpIdle();
}

class OtpSending extends OtpFlowState {
  const OtpSending();
}

class OtpCodeSent extends OtpFlowState {
  const OtpCodeSent({required this.verificationId, required this.phone});
  final String verificationId;
  final String phone;
}

class OtpVerifying extends OtpFlowState {
  const OtpVerifying();
}

class OtpVerified extends OtpFlowState {
  const OtpVerified();
}

class OtpError extends OtpFlowState {
  const OtpError(this.message);
  final String message;
}

class OtpFlowController extends StateNotifier<OtpFlowState> {
  OtpFlowController(this._repo) : super(const OtpIdle());

  final AuthRepository _repo;

  Future<void> sendOtp(String phoneE164) async {
    state = const OtpSending();
    try {
      final verificationId = await _repo.sendOtp(phoneE164);
      state = OtpCodeSent(verificationId: verificationId, phone: phoneE164);
    } catch (e) {
      state = OtpError(e.toString());
    }
  }

  Future<bool> verifyOtp(String smsCode) async {
    final current = state;
    if (current is! OtpCodeSent) return false;
    state = const OtpVerifying();
    try {
      await _repo.verifyOtp(
        verificationId: current.verificationId,
        smsCode: smsCode,
      );
      state = const OtpVerified();
      return true;
    } catch (e) {
      state = OtpError(e.toString());
      return false;
    }
  }

  void reset() => state = const OtpIdle();
}

final otpFlowProvider =
    StateNotifierProvider<OtpFlowController, OtpFlowState>((ref) {
  return OtpFlowController(ref.watch(authRepositoryProvider));
});
