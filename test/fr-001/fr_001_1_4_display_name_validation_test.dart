import 'package:flutter_test/flutter_test.dart';

/// FR-001.1.4: The system SHALL validate that the display name is between 2 and 50 characters
///
/// This test suite verifies that display name validation enforces the length requirements.

// Display name validator class
class DisplayNameValidator {
  static const int minLength = 2;
  static const int maxLength = 50;

  /// Validates display name length (2-50 characters)
  static bool isValid(String displayName) {
    final trimmed = displayName.trim();
    return trimmed.length >= minLength && trimmed.length <= maxLength;
  }

  /// Returns validation error message or null if valid
  static String? getValidationError(String displayName) {
    final trimmed = displayName.trim();

    if (trimmed.isEmpty) {
      return 'Display name is required';
    }
    if (trimmed.length < minLength) {
      return 'Name must be between $minLength and $maxLength characters';
    }
    if (trimmed.length > maxLength) {
      return 'Name must be between $minLength and $maxLength characters';
    }
    return null;
  }

  /// Sanitizes the display name (trims whitespace)
  static String sanitize(String displayName) {
    return displayName.trim();
  }

  /// Returns the length of the sanitized display name
  static int getLength(String displayName) {
    return displayName.trim().length;
  }
}

void main() {
  group('FR-001.1.4: Display Name Validation (2-50 characters)', () {
    group('Minimum length (2 characters)', () {
      test('should reject display name with 0 characters (empty)', () {
        expect(DisplayNameValidator.isValid(''), isFalse);
      });

      test('should reject display name with 1 character', () {
        expect(DisplayNameValidator.isValid('A'), isFalse);
      });

      test('should accept display name with exactly 2 characters', () {
        expect(DisplayNameValidator.isValid('AB'), isTrue);
      });

      test('should accept display name with 3 characters', () {
        expect(DisplayNameValidator.isValid('ABC'), isTrue);
      });

      test('should reject whitespace-only name that becomes too short', () {
        expect(DisplayNameValidator.isValid('   A   '), isFalse);
      });
    });

    group('Maximum length (50 characters)', () {
      test('should accept display name with 49 characters', () {
        final name = 'A' * 49;
        expect(DisplayNameValidator.isValid(name), isTrue);
        expect(name.length, equals(49));
      });

      test('should accept display name with exactly 50 characters', () {
        final name = 'A' * 50;
        expect(DisplayNameValidator.isValid(name), isTrue);
        expect(name.length, equals(50));
      });

      test('should reject display name with 51 characters', () {
        final name = 'A' * 51;
        expect(DisplayNameValidator.isValid(name), isFalse);
        expect(name.length, equals(51));
      });

      test('should reject display name with 100 characters', () {
        final name = 'A' * 100;
        expect(DisplayNameValidator.isValid(name), isFalse);
      });
    });

    group('Valid display names', () {
      test('should accept regular name', () {
        expect(DisplayNameValidator.isValid('John Doe'), isTrue);
      });

      test('should accept name with numbers', () {
        expect(DisplayNameValidator.isValid('User123'), isTrue);
      });

      test('should accept name with special characters', () {
        expect(DisplayNameValidator.isValid("John O'Brien"), isTrue);
      });

      test('should accept name with hyphen', () {
        expect(DisplayNameValidator.isValid('Mary-Jane'), isTrue);
      });

      test('should accept name with unicode characters', () {
        expect(DisplayNameValidator.isValid('José García'), isTrue);
      });

      test('should accept name with emoji', () {
        expect(DisplayNameValidator.isValid('John 🚀'), isTrue);
      });

      test('should accept name with multiple spaces', () {
        expect(DisplayNameValidator.isValid('John van der Berg'), isTrue);
      });

      test('should accept initials', () {
        expect(DisplayNameValidator.isValid('JD'), isTrue);
      });
    });

    group('Whitespace handling', () {
      test('should trim leading whitespace before validation', () {
        expect(DisplayNameValidator.isValid('   John'), isTrue);
        expect(DisplayNameValidator.getLength('   John'), equals(4));
      });

      test('should trim trailing whitespace before validation', () {
        expect(DisplayNameValidator.isValid('John   '), isTrue);
        expect(DisplayNameValidator.getLength('John   '), equals(4));
      });

      test('should trim both leading and trailing whitespace', () {
        expect(DisplayNameValidator.isValid('   John Doe   '), isTrue);
        expect(DisplayNameValidator.getLength('   John Doe   '), equals(8));
      });

      test('should reject name that is only whitespace', () {
        expect(DisplayNameValidator.isValid('     '), isFalse);
      });

      test('should reject empty string after trimming', () {
        expect(DisplayNameValidator.isValid('   '), isFalse);
      });

      test('should handle tab characters', () {
        expect(DisplayNameValidator.isValid('\tJohn\t'), isTrue);
      });

      test('should handle newline characters', () {
        expect(DisplayNameValidator.isValid('\nJohn\n'), isTrue);
      });
    });

    group('Validation error messages', () {
      test('should return error for empty display name', () {
        expect(
          DisplayNameValidator.getValidationError(''),
          equals('Display name is required'),
        );
      });

      test('should return error for whitespace-only display name', () {
        expect(
          DisplayNameValidator.getValidationError('   '),
          equals('Display name is required'),
        );
      });

      test('should return error for single character display name', () {
        expect(
          DisplayNameValidator.getValidationError('A'),
          equals('Name must be between 2 and 50 characters'),
        );
      });

      test('should return error for display name exceeding 50 characters', () {
        final longName = 'A' * 51;
        expect(
          DisplayNameValidator.getValidationError(longName),
          equals('Name must be between 2 and 50 characters'),
        );
      });

      test('should return null for valid display name', () {
        expect(
          DisplayNameValidator.getValidationError('John Doe'),
          isNull,
        );
      });
    });

    group('Sanitization', () {
      test('should trim leading whitespace', () {
        expect(
          DisplayNameValidator.sanitize('   John'),
          equals('John'),
        );
      });

      test('should trim trailing whitespace', () {
        expect(
          DisplayNameValidator.sanitize('John   '),
          equals('John'),
        );
      });

      test('should preserve internal whitespace', () {
        expect(
          DisplayNameValidator.sanitize('   John Doe   '),
          equals('John Doe'),
        );
      });

      test('should return empty string for whitespace-only input', () {
        expect(
          DisplayNameValidator.sanitize('     '),
          equals(''),
        );
      });
    });

    group('Edge cases', () {
      test('should handle display name at exact boundary of 2 characters', () {
        expect(DisplayNameValidator.isValid('AB'), isTrue);
        expect(DisplayNameValidator.isValid('A'), isFalse);
      });

      test('should handle display name at exact boundary of 50 characters', () {
        final name50 = 'A' * 50;
        final name51 = 'A' * 51;
        expect(DisplayNameValidator.isValid(name50), isTrue);
        expect(DisplayNameValidator.isValid(name51), isFalse);
      });

      test('should count unicode characters correctly', () {
        // Each emoji typically counts as 1-2 characters depending on implementation
        final name = '👨‍👩‍👧‍👦John';
        expect(DisplayNameValidator.getLength(name), greaterThanOrEqualTo(5));
      });

      test('should handle mixed alphanumeric and special characters', () {
        expect(DisplayNameValidator.isValid('User_123!@#'), isTrue);
      });

      test('should handle very long name that exceeds max length', () {
        final veryLongName = 'A' * 1000;
        expect(DisplayNameValidator.isValid(veryLongName), isFalse);
      });
    });

    group('Length calculation', () {
      test('should return correct length for simple name', () {
        expect(DisplayNameValidator.getLength('John'), equals(4));
      });

      test('should return correct length after trimming', () {
        expect(DisplayNameValidator.getLength('  John  '), equals(4));
      });

      test('should return 0 for empty string', () {
        expect(DisplayNameValidator.getLength(''), equals(0));
      });

      test('should return 0 for whitespace-only string', () {
        expect(DisplayNameValidator.getLength('   '), equals(0));
      });
    });
  });
}
