/// Pure domain entity representing an authenticated user.
/// No Firebase imports — this is independent of any data source.
class AppUser {
  const AppUser({
    required this.id,
    this.phone,
    this.email,
    this.displayName,
    this.photoUrl,
    this.createdAt,
  });

  final String id;
  final String? phone;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final DateTime? createdAt;

  AppUser copyWith({
    String? id,
    String? phone,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
