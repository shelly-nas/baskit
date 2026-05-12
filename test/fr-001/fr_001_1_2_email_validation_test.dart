import 'package:flutter_test/flutter_test.dart';

/// FR-001.1.2: The system SHALL validate email format according to RFC 5322 standards
///
/// This test suite verifies that email validation follows RFC 5322 standards
/// for proper email format validation.

// Email validator class following RFC 5322 standards
class EmailValidator {
  // RFC 5322 compliant email regex pattern
  // This pattern covers most valid email formats according to the standard
  static final RegExp _emailRegExp = RegExp(
    r'^(?:[a-zA-Z0-9!#$%&'"*+/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&'"*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-zA-Z0-9-]*[a-zA-Z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])$',
  );

  /// Validates an email address according to RFC 5322 standards
  static bool isValid(String email) {
    if (email.isEmpty) return false;
    if (email.length > 254) return false; // RFC 5321 max length
    return _emailRegExp.hasMatch(email);
  }

  /// Returns validation error message or null if valid
  static String? getValidationError(String email) {
    if (email.isEmpty) {
      return 'Email is required';
    }
    if (email.length > 254) {
      return 'Email address is too long';
    }
    if (!email.contains('@')) {
      return 'Please enter a valid email address';
    }
    if (!_emailRegExp.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
}

void main() {
  group('FR-001.1.2: Email Format Validation (RFC 5322)', () {
    group('Valid email formats', () {
      test('should accept standard email format', () {
        expect(EmailValidator.isValid('user@example.com'), isTrue);
      });

      test('should accept email with subdomain', () {
        expect(EmailValidator.isValid('user@mail.example.com'), isTrue);
      });

      test('should accept email with numbers in local part', () {
        expect(EmailValidator.isValid('user123@example.com'), isTrue);
      });

      test('should accept email with dots in local part', () {
        expect(EmailValidator.isValid('first.last@example.com'), isTrue);
      });

      test('should accept email with plus sign', () {
        expect(EmailValidator.isValid('user+tag@example.com'), isTrue);
      });

      test('should accept email with hyphen in domain', () {
        expect(EmailValidator.isValid('user@my-domain.com'), isTrue);
      });

      test('should accept email with numbers in domain', () {
        expect(EmailValidator.isValid('user@example123.com'), isTrue);
      });

      test('should accept email with underscore in local part', () {
        expect(EmailValidator.isValid('user_name@example.com'), isTrue);
      });

      test('should accept email with two-letter TLD', () {
        expect(EmailValidator.isValid('user@example.nl'), isTrue);
      });

      test('should accept email with long TLD', () {
        expect(EmailValidator.isValid('user@example.technology'), isTrue);
      });

      test('should accept email with multiple subdomains', () {
        expect(
            EmailValidator.isValid('user@sub1.sub2.example.com'), isTrue);
      });

      test('should accept email with uppercase letters', () {
        expect(EmailValidator.isValid('User@Example.COM'), isTrue);
      });

      test('should accept email with mixed case', () {
        expect(EmailValidator.isValid('John.Doe@Example.Com'), isTrue);
      });
    });

    group('Invalid email formats', () {
      test('should reject empty string', () {
        expect(EmailValidator.isValid(''), isFalse);
      });

      test('should reject email without @ symbol', () {
        expect(EmailValidator.isValid('userexample.com'), isFalse);
      });

      test('should reject email without domain', () {
        expect(EmailValidator.isValid('user@'), isFalse);
      });

      test('should reject email without local part', () {
        expect(EmailValidator.isValid('@example.com'), isFalse);
      });

      test('should reject email with multiple @ symbols', () {
        expect(EmailValidator.isValid('user@@example.com'), isFalse);
      });

      test('should reject email with spaces', () {
        expect(EmailValidator.isValid('user @example.com'), isFalse);
      });

      test('should reject email with leading dot in local part', () {
        expect(EmailValidator.isValid('.user@example.com'), isFalse);
      });

      test('should reject email with trailing dot in local part', () {
        expect(EmailValidator.isValid('user.@example.com'), isFalse);
      });

      test('should reject email with consecutive dots in local part', () {
        expect(EmailValidator.isValid('user..name@example.com'), isFalse);
      });

      test('should reject email without TLD', () {
        expect(EmailValidator.isValid('user@example'), isFalse);
      });

      test('should reject email with invalid characters', () {
        expect(EmailValidator.isValid('user<>@example.com'), isFalse);
      });

      test('should reject email with leading hyphen in domain', () {
        expect(EmailValidator.isValid('user@-example.com'), isFalse);
      });

      test('should reject email with trailing hyphen in domain', () {
        expect(EmailValidator.isValid('user@example-.com'), isFalse);
      });

      test('should reject email that exceeds max length (254 chars)', () {
        final longLocal = 'a' * 250;
        final email = '$longLocal@example.com';
        expect(EmailValidator.isValid(email), isFalse);
      });
    });

    group('Validation error messages', () {
      test('should return error for empty email', () {
        expect(
          EmailValidator.getValidationError(''),
          equals('Email is required'),
        );
      });

      test('should return error for email without @', () {
        expect(
          EmailValidator.getValidationError('userexample.com'),
          equals('Please enter a valid email address'),
        );
      });

      test('should return error for too long email', () {
        final longEmail = '${'a' * 250}@example.com';
        expect(
          EmailValidator.getValidationError(longEmail),
          equals('Email address is too long'),
        );
      });

      test('should return null for valid email', () {
        expect(
          EmailValidator.getValidationError('user@example.com'),
          isNull,
        );
      });
    });

    group('Edge cases', () {
      test('should handle null-like empty string', () {
        expect(EmailValidator.isValid(''), isFalse);
      });

      test('should handle whitespace-only string', () {
        expect(EmailValidator.isValid('   '), isFalse);
      });

      test('should accept minimum valid email (a@b.co)', () {
        expect(EmailValidator.isValid('a@b.co'), isTrue);
      });

      test('should accept email at max reasonable length', () {
        // Create a valid email close to 254 character limit
        final localPart = 'a' * 50;
        final domain = 'b' * 50;
        final email = '$localPart@$domain.com';
        expect(email.length < 254, isTrue);
        expect(EmailValidator.isValid(email), isTrue);
      });
    });
  });
}
