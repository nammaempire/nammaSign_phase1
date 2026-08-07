/// Reusable form validators. Return `null` on success, error string on failure.
class Validators {
  Validators._();

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w\.-]+@[\w-]+\.[\w\.-]+$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Enter a valid phone number';
    return null;
  }

  static String? otp(String? value, {int length = 6}) {
    if (value == null || value.length != length) {
      return 'Enter the $length-digit code';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'OTP must be numeric';
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Indian business identifiers (format + checksum validation only).
  //
  // These confirm the *shape* of the number and catch typos — they do NOT
  // prove the entity exists. Real authenticity (name match, active status)
  // needs a server-side verification API (PAN / GST / MCA).
  // ---------------------------------------------------------------------------

  /// PAN — 10 chars: 5 letters, 4 digits, 1 letter (e.g. `AAACX1234C`).
  /// The 4th letter encodes holder type; pass [corporate] to require `C`
  /// (companies), which rejects an individual's PAN (`P`).
  static String? pan(String? value, {bool corporate = false}) {
    final v = (value ?? '').trim().toUpperCase();
    if (v.isEmpty) return 'PAN is required';
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(v)) {
      return 'Enter a valid 10-character PAN (e.g. AAACX1234C)';
    }
    if (corporate && v[3] != 'C') {
      return 'This looks like a personal PAN — a company PAN has C as its 4th letter';
    }
    return null;
  }

  /// GSTIN — 15 chars. Validates the format AND the mod-36 check digit in
  /// the last position, so most typos are caught offline. Characters 3–12
  /// are the entity's PAN, so [expectedPan] (if given) is cross-checked.
  static String? gstin(String? value, {String? expectedPan}) {
    final v = (value ?? '').trim().toUpperCase();
    if (v.isEmpty) return 'GSTIN is required';
    if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$')
        .hasMatch(v)) {
      return 'Enter a valid 15-character GSTIN';
    }
    if (!_gstinChecksumOk(v)) {
      return 'GSTIN check digit failed — please re-check for typos';
    }
    if (expectedPan != null) {
      final panPart = expectedPan.trim().toUpperCase();
      if (panPart.length == 10 && v.substring(2, 12) != panPart) {
        return "GSTIN doesn't match the PAN entered";
      }
    }
    return null;
  }

  /// CIN — 21 chars: `L`/`U` + 5-digit industry code + 2-letter state +
  /// 4-digit year + 3-letter ownership type + 6-digit registration number
  /// (e.g. `L85110KA1995PLC019126`).
  static String? cin(String? value) {
    final v = (value ?? '').trim().toUpperCase();
    if (v.isEmpty) return 'CIN is required';
    if (!RegExp(r'^[LU][0-9]{5}[A-Z]{2}[0-9]{4}[A-Z]{3}[0-9]{6}$')
        .hasMatch(v)) {
      return 'Enter a valid 21-character CIN (e.g. L85110KA1995PLC019126)';
    }
    return null;
  }

  /// Accepts either a valid PAN (10 chars) or a valid CIN (21 chars) —
  /// used by the corporate signup form's combined "PAN / CIN" field.
  static String? panOrCin(String? value, {bool corporatePan = true}) {
    final v = (value ?? '').trim().toUpperCase();
    if (v.isEmpty) return 'PAN or CIN is required';
    if (v.length == 10) return pan(v, corporate: corporatePan);
    if (v.length == 21) return cin(v);
    return 'Enter a valid PAN (10 chars) or CIN (21 chars)';
  }

  /// Standard GSTIN check-digit algorithm (base-36, alternating 1/2 weights).
  static bool _gstinChecksumOk(String gstin) {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    var sum = 0;
    for (var i = 0; i < 14; i++) {
      final codePoint = chars.indexOf(gstin[i]);
      if (codePoint < 0) return false;
      final factor = i.isEven ? 1 : 2;
      final digit = factor * codePoint;
      sum += (digit ~/ 36) + (digit % 36);
    }
    final checksum = (36 - (sum % 36)) % 36;
    return chars[checksum] == gstin[14];
  }

  /// Aadhaar — 12 digits, not starting with 0 or 1, with a valid Verhoeff
  /// check digit (the last digit). Validates the number's shape + checksum
  /// OFFLINE, which rejects typos and made-up numbers.
  ///
  /// This does NOT prove the Aadhaar exists or belongs to the person, and it
  /// does NOT verify an uploaded card image — genuine Aadhaar verification
  /// requires UIDAI eKYC (OTP / offline XML) through a licensed provider.
  static String? aadhaar(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Aadhaar number is required';
    if (digits.length != 12) return 'Enter a valid 12-digit Aadhaar number';
    if (digits[0] == '0' || digits[0] == '1') {
      return 'Aadhaar cannot start with 0 or 1';
    }
    if (!_verhoeffValid(digits)) {
      return 'Aadhaar check digit failed — please re-check the number';
    }
    return null;
  }

  // Verhoeff multiplication (d) and permutation (p) tables.
  static const List<List<int>> _vD = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
    [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
    [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
    [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
    [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
    [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
    [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
    [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
    [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
  ];
  static const List<List<int>> _vP = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
    [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
    [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
    [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
    [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
    [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
    [7, 0, 4, 6, 9, 1, 3, 2, 5, 8],
  ];

  static bool _verhoeffValid(String digits) {
    var c = 0;
    final rev = digits.split('').reversed.toList();
    for (var i = 0; i < rev.length; i++) {
      c = _vD[c][_vP[i % 8][int.parse(rev[i])]];
    }
    return c == 0;
  }
}
