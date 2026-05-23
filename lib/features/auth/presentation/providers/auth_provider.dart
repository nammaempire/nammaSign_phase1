import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fake_auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Concrete repository.
///
/// Phase 1a: uses [FakeAuthRepository] (in-memory, no backend).
/// Phase 1b: swap to FirebaseAuthRepository — only this line changes.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = FakeAuthRepository();
  ref.onDispose(repo.dispose);
  return repo;
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
