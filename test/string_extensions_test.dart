// Unit tests for the String extensions (capitalized, initials, isValidEmail,
// isNumeric).

import 'package:flutter_test/flutter_test.dart';
import 'package:nammasign_phase1/core/extensions/string_extensions.dart';

void main() {
  group('capitalized', () {
    test('upper-cases the first character only', () {
      expect('hello'.capitalized, 'Hello');
      expect('a'.capitalized, 'A');
      expect('already Up'.capitalized, 'Already Up');
    });

    test('leaves an empty string untouched', () {
      expect(''.capitalized, '');
    });
  });

  group('initials', () {
    test('first + last initial for multi-word names', () {
      expect('John Doe'.initials, 'JD');
      expect('  jane   mary  '.initials, 'JM');
    });

    test('single initial for a one-word name', () {
      expect('John'.initials, 'J');
    });
  });

  group('isValidEmail', () {
    test('true for valid, false for invalid', () {
      expect('user@example.com'.isValidEmail, isTrue);
      expect('  spaced@example.com  '.isValidEmail, isTrue);
      expect('nope'.isValidEmail, isFalse);
    });
  });

  group('isNumeric', () {
    test('true for integers (incl. negative), false otherwise', () {
      expect('123'.isNumeric, isTrue);
      expect('-5'.isNumeric, isTrue);
      expect('12.3'.isNumeric, isFalse);
      expect('abc'.isNumeric, isFalse);
    });
  });
}
