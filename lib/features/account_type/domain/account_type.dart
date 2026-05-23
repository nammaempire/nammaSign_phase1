/// Account type the user picks during signup.
///
/// Affects verification flow (PAN/CIN for corporate, Aadhaar for individual)
/// and what booking options are surfaced (multi-day campaigns vs single-day
/// slots).
enum AccountType {
  corporate,
  individual;

  String get storageValue => name;

  static AccountType? fromStorage(String? raw) {
    if (raw == null) return null;
    return AccountType.values.firstWhere(
      (e) => e.storageValue == raw,
      orElse: () => AccountType.corporate,
    );
  }

  String get displayLabel => switch (this) {
        AccountType.corporate => 'Corporate',
        AccountType.individual => 'Individual',
      };
}
