import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/picked_file.dart';
import '../../../account_type/domain/account_type.dart';
import '../../domain/user_profile.dart';

abstract class UserProfileRepository {
  Stream<UserProfile?> watch(String uid);
  Future<UserProfile?> get(String uid);

  /// Saves [type] to `users/{uid}.accountType`. Called from the
  /// AccountTypeScreen Continue button.
  Future<void> setAccountType(String uid, AccountType type);

  /// Writes the corporate profile sub-object. Called from the
  /// CorporateSignupScreen Continue button.
  Future<void> saveCorporate(String uid, CorporateProfile data);

  /// Writes the individual profile sub-object. Called from the
  /// IndividualSignupScreen Continue button.
  Future<void> saveIndividual(String uid, IndividualProfile data);

  /// Uploads the picked KYC documents to Storage under
  /// `users/{uid}/kycDocs/{label}.{ext}`, then writes the resulting
  /// download URLs to `users/{uid}.kycDocs` and sets `kycStatus` to
  /// `pending` so the admin can review. [docs] maps a label
  /// (e.g. 'aadhaarFront', 'panCin') to the picked file. No-op if empty.
  Future<void> uploadKycDocs(String uid, Map<String, PickedFile> docs);

  /// Admin: flip the KYC verification state for a user.
  /// [status] should be 'verified', 'rejected', or 'pending'.
  Future<void> adminSetKycStatus(String uid, String status, {String? note});
}

class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository({
    required this._firestore,
    required this._storage,
  });

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection(FirestoreCollections.users).doc(uid);

  @override
  Stream<UserProfile?> watch(String uid) {
    return _doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserProfile.fromFirestore(snap);
    });
  }

  @override
  Future<UserProfile?> get(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromFirestore(snap);
  }

  @override
  Future<void> setAccountType(String uid, AccountType type) async {
    await _doc(uid).set(
      {
        'accountType': type.storageValue,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> saveCorporate(String uid, CorporateProfile data) async {
    await _doc(uid).set(
      {
        'accountType': AccountType.corporate.storageValue,
        'org': data.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> saveIndividual(String uid, IndividualProfile data) async {
    await _doc(uid).set(
      {
        'accountType': AccountType.individual.storageValue,
        'personal': data.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> uploadKycDocs(
    String uid,
    Map<String, PickedFile> docs,
  ) async {
    if (docs.isEmpty) return;
    final urls = <String, String>{};
    for (final entry in docs.entries) {
      final file = entry.value;
      final ext = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : 'jpg';
      final ref = _storage
          .ref()
          .child('users')
          .child(uid)
          .child('kycDocs')
          .child('${entry.key}.$ext');
      final task = await ref.putFile(File(file.path));
      urls[entry.key] = await task.ref.getDownloadURL();
    }
    await _doc(uid).set(
      {
        'kycDocs': urls,
        'kycStatus': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> adminSetKycStatus(
    String uid,
    String status, {
    String? note,
  }) async {
    await _doc(uid).set(
      {
        'kycStatus': status,
        if (note != null && note.isNotEmpty) 'kycNote': note,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
