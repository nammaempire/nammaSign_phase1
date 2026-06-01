import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/app_user.dart';

/// Data-layer model. Bridges the pure-Dart [AppUser] entity to Firebase
/// SDK types (Firebase Auth user + Firestore doc).
class UserModel extends AppUser {
  const UserModel({
    required super.id,
    super.phone,
    super.email,
    super.displayName,
    super.photoUrl,
    super.createdAt,
  });

  /// Build from a freshly-authenticated Firebase Auth user. Useful right
  /// after sign-in before the Firestore profile has been read.
  factory UserModel.fromFirebaseUser(fb.User user) {
    return UserModel(
      id: user.uid,
      phone: user.phoneNumber,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime,
    );
  }

  /// Build from the `users/{uid}` Firestore document.
  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data() ?? const <String, dynamic>{};
    return UserModel(
      id: snap.id,
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Pure JSON serialization (no Firebase imports).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'createdAt': createdAt?.toIso8601String(),
      };

  /// Write the user document on first sign-in. The `onUserCreate` Cloud
  /// Function handles this server-side too, but we write client-side as
  /// well in case the function trigger is delayed.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': id,
      'phone': phone,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'accountType': null,
      'kycStatus': 'none',
      'fcmTokens': <String>[],
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
