import 'package:cloud_firestore/cloud_firestore.dart';

import '../../account_type/domain/account_type.dart';

/// App-level identity. Reads from `users/{uid}` in Firestore.
///
/// Distinct from `AppUser` (which is just the Firebase Auth identity).
/// AppUser is created the instant you sign in; UserProfile is created
/// by [FirebaseAuthRepository._ensureUserDocument] and gets enriched as
/// the user completes account setup.
class UserProfile {
  const UserProfile({
    required this.uid,
    this.phone,
    this.email,
    this.displayName,
    this.photoUrl,
    this.accountType,
    this.corporate,
    this.individual,
    this.kycStatus = 'none',
    this.kycDocs = const {},
    this.fcmTokens = const [],
  });

  final String uid;
  final String? phone;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  /// `null` means the user signed in but hasn't completed account setup
  /// yet. The router gates these users into the account-type → signup
  /// flow until they pick + fill in their details.
  final AccountType? accountType;

  final CorporateProfile? corporate;
  final IndividualProfile? individual;

  final String kycStatus;

  /// Uploaded KYC document URLs keyed by label (e.g. `aadhaarFront`,
  /// `panCin`). Written by `UserProfileRepository.uploadKycDocs` during
  /// signup; admin reads these to review.
  final Map<String, String> kycDocs;

  final List<String> fcmTokens;

  /// Setup is "complete" when the user has both picked an account type
  /// AND filled in the matching sub-profile on the signup form. Just
  /// picking the type isn't enough — otherwise the router would yank
  /// them to /home in between account-type → signup.
  bool get isSetupComplete {
    switch (accountType) {
      case AccountType.corporate:
        return corporate != null && corporate!.name.isNotEmpty;
      case AccountType.individual:
        return individual != null && individual!.fullName.isNotEmpty;
      case null:
        return false;
    }
  }

  /// Best display name based on what's filled in.
  String get bestDisplayName {
    if (corporate?.managerName.isNotEmpty == true) {
      return corporate!.managerName;
    }
    if (individual?.fullName.isNotEmpty == true) {
      return individual!.fullName;
    }
    if (displayName?.isNotEmpty == true) return displayName!;
    if (phone?.isNotEmpty == true) return phone!;
    return 'Guest';
  }

  /// Best organisation / context label.
  String get bestOrgLabel {
    if (corporate?.name.isNotEmpty == true) return corporate!.name;
    if (individual?.fullName.isNotEmpty == true) return 'Personal Account';
    return '';
  }

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final d = snap.data() ?? const <String, dynamic>{};
    final org = d['org'] as Map<String, dynamic>?;
    final personal = d['personal'] as Map<String, dynamic>?;

    return UserProfile(
      uid: snap.id,
      phone: d['phone'] as String?,
      email: d['email'] as String?,
      displayName: d['displayName'] as String?,
      photoUrl: d['photoUrl'] as String?,
      accountType: AccountType.fromStorage(d['accountType'] as String?),
      corporate: org == null ? null : CorporateProfile.fromMap(org),
      individual:
          personal == null ? null : IndividualProfile.fromMap(personal),
      kycStatus: (d['kycStatus'] as String?) ?? 'none',
      kycDocs: (d['kycDocs'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          const {},
      fcmTokens: ((d['fcmTokens'] as List?)?.cast<String>()) ?? const [],
    );
  }
}

class CorporateProfile {
  const CorporateProfile({
    required this.name,
    required this.panCin,
    required this.officialEmail,
    required this.managerName,
    required this.managerPhone,
  });

  final String name;
  final String panCin;
  final String officialEmail;
  final String managerName;
  final String managerPhone;

  factory CorporateProfile.fromMap(Map<String, dynamic> m) {
    return CorporateProfile(
      name: (m['name'] as String?) ?? '',
      panCin: (m['panCin'] as String?) ?? '',
      officialEmail: (m['officialEmail'] as String?) ?? '',
      managerName: (m['managerName'] as String?) ?? '',
      managerPhone: (m['managerPhone'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'panCin': panCin,
        'officialEmail': officialEmail,
        'managerName': managerName,
        'managerPhone': managerPhone,
      };
}

class IndividualProfile {
  const IndividualProfile({
    required this.fullName,
    required this.dob,
    required this.mobile,
    required this.aadhaarLast4,
  });

  final String fullName;
  final DateTime? dob;
  final String mobile;

  /// Only the last 4 digits of the Aadhaar number are persisted — never
  /// the full 12-digit number. The full number is sent server-side for
  /// verification (Cloud Function in Phase 1c) and discarded after.
  final String aadhaarLast4;

  factory IndividualProfile.fromMap(Map<String, dynamic> m) {
    return IndividualProfile(
      fullName: (m['fullName'] as String?) ?? '',
      dob: (m['dob'] as Timestamp?)?.toDate(),
      mobile: (m['mobile'] as String?) ?? '',
      aadhaarLast4: (m['aadhaarLast4'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        if (dob != null) 'dob': Timestamp.fromDate(dob!),
        'mobile': mobile,
        'aadhaarLast4': aadhaarLast4,
      };
}
