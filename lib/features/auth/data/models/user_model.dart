import '../../domain/entities/app_user.dart';

/// Data-layer model. Pure Dart for now (no Firebase imports).
/// When Firebase comes back in Phase 1b, add `fromFirebaseUser` and
/// `fromFirestore` factories alongside the existing JSON ones.
class UserModel extends AppUser {
  const UserModel({
    required super.id,
    super.phone,
    super.email,
    super.displayName,
    super.photoUrl,
    super.createdAt,
  });

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
}
