// Unit tests for form validators. Each returns null on success, an error
// string on failure.

import 'package:flutter_test/flutter_test.dart';
import 'package:nammasign_phase1/core/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('rejects null and blank, accepts non-empty', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required('   '), isNotNull);
      expect(Validators.required('x'), isNull);
    });

    test('uses the field name in the message', () {
      expect(Validators.required(null, field: 'Name'), 'Name is required');
    });
  });

  group('Validators.email', () {
    test('accepts a valid address', () {
      expect(Validators.email('user@example.com'), isNull);
    });

    test('rejects empty and malformed', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('not-an-email'), 'Enter a valid email');
      expect(Validators.email('a@b'), 'Enter a valid email');
    });
  });

  group('Validators.phone', () {
    test('accepts 10+ digits, ignoring spaces and symbols', () {
      expect(Validators.phone('9876543210'), isNull);
      expect(Validators.phone('+91 98765 43210'), isNull);
    });

    test('rejects empty and too-short', () {
      expect(Validators.phone(''), 'Phone number is required');
      expect(Validators.phone('12345'), 'Enter a valid phone number');
    });
  });

  group('Validators.otp', () {
    test('accepts a 6-digit numeric code', () {
      expect(Validators.otp('123456'), isNull);
    });

    test('rejects wrong length and non-numeric', () {
      expect(Validators.otp('123'), isNotNull);
      expect(Validators.otp('12345a'), 'OTP must be numeric');
    });

    test('respects a custom length', () {
      expect(Validators.otp('1234', length: 4), isNull);
    });
  });

  group('Validators.password', () {
    test('accepts >= min length', () {
      expect(Validators.password('longenough'), isNull);
    });

    test('rejects empty and too-short', () {
      expect(Validators.password(null), 'Password is required');
      expect(Validators.password('short'),
          'Password must be at least 8 characters');
    });
  });
}
