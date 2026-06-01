import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Real Firebase implementation of [AuthRepository]. Drops in as a
/// replacement for `FakeAuthRepository` — the rest of the app talks to
/// the abstract interface only.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required fb.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _auth = firebaseAuth,
        _firestore = firestore;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // ---------------------------------------------------------------------------
  // Current user / state stream
  // ---------------------------------------------------------------------------

  @override
  AppUser? get currentUser {
    final u = _auth.currentUser;
    return u == null ? null : UserModel.fromFirebaseUser(u);
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map(
          (u) => u == null ? null : UserModel.fromFirebaseUser(u),
        );
  }

  // ---------------------------------------------------------------------------
  // Phone OTP
  // ---------------------------------------------------------------------------

  @override
  Future<String> sendOtp(String phoneNumber) async {
    final completer = Completer<String>();
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          // Android instant verification — sign in immediately if the SMS
          // is auto-detected. We still complete with a verificationId so
          // the UI can show OTP entry; user just won't need to type it.
          try {
            await _auth.signInWithCredential(credential);
          } catch (e, st) {
            appLogger.w('Auto sign-in failed', error: e, stackTrace: st);
          }
        },
        verificationFailed: (e) {
          if (!completer.isCompleted) {
            completer.completeError(
              AuthException(
                _humanizeAuthError(e),
                code: e.code,
              ),
            );
          }
        },
        codeSent: (verificationId, _) {
          if (!completer.isCompleted) completer.complete(verificationId);
        },
        codeAutoRetrievalTimeout: (_) {},
      );
      return completer.future;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_humanizeAuthError(e), code: e.code);
    } catch (e, st) {
      appLogger.e('sendOtp failed', error: e, stackTrace: st);
      throw const AuthException('Could not send OTP. Try again.');
    }
  }

  @override
  Future<AppUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        throw const AuthException('Sign-in succeeded but user is null');
      }
      final model = UserModel.fromFirebaseUser(user);
      await _ensureUserDocument(model);
      return model;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_humanizeAuthError(e), code: e.code);
    }
  }

  // ---------------------------------------------------------------------------
  // Email / password (kept for testing parity with FakeAuthRepository —
  // production users will go through phone OTP or social)
  // ---------------------------------------------------------------------------

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return UserModel.fromFirebaseUser(result.user!);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_humanizeAuthError(e), code: e.code);
    }
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final model = UserModel.fromFirebaseUser(result.user!);
      await _ensureUserDocument(model);
      return model;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_humanizeAuthError(e), code: e.code);
    }
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the picker.
        throw const AuthException('Sign-in cancelled', code: 'cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        throw const AuthException('Google sign-in succeeded but user is null');
      }

      final model = UserModel.fromFirebaseUser(user);
      await _ensureUserDocument(model);
      return model;
    } on AuthException {
      rethrow;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_humanizeAuthError(e), code: e.code);
    } catch (e, st) {
      appLogger.e('Google sign-in failed', error: e, stackTrace: st);
      throw const AuthException('Could not sign in with Google. Try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Sign-out
  // ---------------------------------------------------------------------------

  @override
  Future<void> signOut() async {
    // Sign out of Google too so the picker shows again next time.
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Non-fatal — user might never have signed in with Google.
    }
    await _auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Creates `users/{uid}` on first sign-in. The `onUserCreate` Cloud
  /// Function does this too — having both means the doc always exists
  /// even if one path fails.
  Future<void> _ensureUserDocument(UserModel user) async {
    final ref =
        _firestore.collection(FirestoreCollections.users).doc(user.id);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set(user.toFirestore());
    }
  }

  String _humanizeAuthError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'That phone number doesn\'t look right.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a few minutes and try again.';
      case 'invalid-verification-code':
        return 'Invalid code. Check the SMS and re-enter.';
      case 'session-expired':
        return 'That code expired. Tap "Resend" to get a new one.';
      case 'network-request-failed':
        return 'No internet. Check your connection.';
      case 'app-not-authorized':
        return 'App configuration error. Contact support.';
      default:
        return e.message ?? 'Something went wrong. Try again.';
    }
  }
}
