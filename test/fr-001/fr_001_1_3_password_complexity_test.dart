import 'package:flutter_test/flutter_test.dart';

/// FR-001.1.3: The system SHALL enforce password complexity requirements:
/// - Minimum 8 characters
/// - At least one uppercase letter
/// - At least one lowercase letter
/// - At least one number
/// - At least one special character
///
/// This test suite verifies that password validation enforces all complexity requirements.

// Password validator class with complexity requirements
class PasswordValidator {
  static const int minLength = 8;
  static const String specialCharacters = r'@$!%*?&';

  /// Validates password meets all complexity requirements
  static bool isValid(String password) {
    if (password.length < minLength) return false;
    if (!hasUppercase(password)) return false;
    if (!hasLowercase(password)) return false;
    if (!hasNumber(password)) return false;
    if (!hasSpecialCharacter(password)) return false;
    return true;
  }

  /// Check for at least one uppercase letter
  static bool hasUppercase(String password) {
    return password.contains(RegExp(r'[A-Z]'));
  }

  /// Check for at least one lowercase letter
  static bool hasLowercase(String password) {
    return password.contains(RegExp(r'[a-z]'));
  }

  /// Check for at least one number
  static bool hasNumber(String password) {
    return password.contains(RegExp(r'[0-9]'));
  }

  /// Check for at least one special character
  static bool hasSpecialCharacter(String password) {
    return password.contains(RegExp(r'[@$!%*?&]'));
  }

  /// Returns list of validation errors
  static List<String> getValidationErrors(String password) {
    final errors = <String>[];

    if (password.length < minLength) {
      errors.add('Password must be at least $minLength characters long');
    }
    if (!hasUppercase(password)) {
      errors.add('Password must contain at least one uppercase letter');
    }
    if (!hasLowercase(password)) {
      errors.add('Password must contain at least one lowercase letter');
    }
    if (!hasNumber(password)) {
      errors.add('Password must contain at least one number');
    }
    if (!hasSpecialCharacter(password)) {
      errors.add('Password must contain at least one special character ($specialCharacters)');
    }

    return errors;
  }

  /// Returns password strength as percentage (0-100)
  static int getStrength(String password) {
    int score = 0;
    if (password.length >= minLength) score += 20;
    if (password.length >= 12) score += 10;
    if (password.length >= 16) score += 10;
    if (hasUppercase(password)) score += 15;
    if (hasLowercase(password)) score += 15;
    if (hasNumber(password)) score += 15;
    if (hasSpecialCharacter(password)) score += 15;
    return score.clamp(0, 100);
  }
}

void main() {
  group('FR-001.1.3: Password Complexity Requirements', () {
    group('Minimum 8 characters', () {
      test('should reject password with less than 8 characters', () {
        expect(PasswordValidator.isValid('Aa1@567'), isFalse);
      });

      test('should reject password with exactly 7 characters', () {
        expect(PasswordValidator.isValid('Aa1@567'), isFalse);
        expect('Aa1@567'.length, equals(7));
      });

      test('should accept password with exactly 8 characters', () {
        expect(PasswordValidator.isValid('Aa1@5678'), isTrue);
        expect('Aa1@5678'.length, equals(8));
      });

      test('should accept password with more than 8 characters', () {
        expect(PasswordValidator.isValid('Aa1@56789012'), isTrue);
      });

      test('should reject empty password', () {
        expect(PasswordValidator.isValid(''), isFalse);
      });

      test('should reject single character password', () {
        expect(PasswordValidator.isValid('A'), isFalse);
      });
    });

    group('Uppercase letter requirement', () {
      test('should reject password without uppercase letter', () {
        expect(PasswordValidator.isValid('aa1@5678'), isFalse);
      });

      test('should accept password with one uppercase letter', () {
        expect(PasswordValidator.isValid('Aa1@5678'), isTrue);
      });

      test('should accept password with multiple uppercase letters', () {
        expect(PasswordValidator.isValid('AA1@5678'), isTrue);
      });

      test('should detect uppercase letter presence correctly', () {
        expect(PasswordValidator.hasUppercase('ABC'), isTrue);
        expect(PasswordValidator.hasUppercase('abc'), isFalse);
        expect(PasswordValidator.hasUppercase('aBc'), isTrue);
        expect(PasswordValidator.hasUppercase('123'), isFalse);
      });
    });

    group('Lowercase letter requirement', () {
      test('should reject password without lowercase letter', () {
        expect(PasswordValidator.isValid('AA1@5678'), isFalse);
      });

      test('should accept password with one lowercase letter', () {
        expect(PasswordValidator.isValid('Aa1@5678'), isTrue);
      });

      test('should accept password with multiple lowercase letters', () {
        expect(PasswordValidator.isValid('Aab1@567'), isTrue);
      });

      test('should detect lowercase letter presence correctly', () {
        expect(PasswordValidator.hasLowercase('abc'), isTrue);
        expect(PasswordValidator.hasLowercase('ABC'), isFalse);
        expect(PasswordValidator.hasLowercase('AbC'), isTrue);
        expect(PasswordValidator.hasLowercase('123'), isFalse);
      });
    });

    group('Number requirement', () {
      test('should reject password without number', () {
        expect(PasswordValidator.isValid('Aabc@def'), isFalse);
      });

      test('should accept password with one number', () {
        expect(PasswordValidator.isValid('Aa1@bcde'), isTrue);
      });

      test('should accept password with multiple numbers', () {
        expect(PasswordValidator.isValid('Aa12@345'), isTrue);
      });

      test('should detect number presence correctly', () {
        expect(PasswordValidator.hasNumber('123'), isTrue);
        expect(PasswordValidator.hasNumber('abc'), isFalse);
        expect(PasswordValidator.hasNumber('a1b'), isTrue);
        expect(PasswordValidator.hasNumber('ABC'), isFalse);
      });
    });

    group('Special character requirement', () {
      test('should reject password without special character', () {
        expect(PasswordValidator.isValid('Aa123456'), isFalse);
      });

      test('should accept password with @ character', () {
        expect(PasswordValidator.isValid('Aa1@5678'), isTrue);
      });

      test('should accept password with \$ character', () {
        expect(PasswordValidator.isValid('Aa1\$5678'), isTrue);
      });

      test('should accept password with ! character', () {
        expect(PasswordValidator.isValid('Aa1!5678'), isTrue);
      });

      test('should accept password with % character', () {
        expect(PasswordValidator.isValid('Aa1%5678'), isTrue);
      });

      test('should accept password with * character', () {
        expect(PasswordValidator.isValid('Aa1*5678'), isTrue);
      });

      test('should accept password with ? character', () {
        expect(PasswordValidator.isValid('Aa1?5678'), isTrue);
      });

      test('should accept password with & character', () {
        expect(PasswordValidator.isValid('Aa1&5678'), isTrue);
      });

      test('should detect special character presence correctly', () {
        expect(PasswordValidator.hasSpecialCharacter('@'), isTrue);
        expect(PasswordValidator.hasSpecialCharacter('\$'), isTrue);
        expect(PasswordValidator.hasSpecialCharacter('!'), isTrue);
        expect(PasswordValidator.hasSpecialCharacter('%'), isTrue);
        expect(PasswordValidator.hasSpecialCharacter('*'), isTrue);
        expect(PasswordValidator.hasSpecialCharacter('?'), isTrue);
        expect(PasswordValidator.hasSpecialCharacter('&'), isTrue);
        expect(PasswordValidator.hasSpecialCharacter('abc'), isFalse);
        expect(PasswordValidator.hasSpecialCharacter('#'), isFalse);
      });
    });

    group('Combined requirements', () {
      test('should accept password meeting all requirements', () {
        expect(PasswordValidator.isValid('SecureP@ss1'), isTrue);
      });

      test('should reject password missing only uppercase', () {
        final password = 'securep@ss1';
        expect(PasswordValidator.hasUppercase(password), isFalse);
        expect(PasswordValidator.hasLowercase(password), isTrue);
        expect(PasswordValidator.hasNumber(password), isTrue);
        expect(PasswordValidator.hasSpecialCharacter(password), isTrue);
        expect(password.length >= 8, isTrue);
        expect(PasswordValidator.isValid(password), isFalse);
      });

      test('should reject password missing only lowercase', () {
        final password = 'SECUREP@SS1';
        expect(PasswordValidator.hasUppercase(password), isTrue);
        expect(PasswordValidator.hasLowercase(password), isFalse);
        expect(PasswordValidator.hasNumber(password), isTrue);
        expect(PasswordValidator.hasSpecialCharacter(password), isTrue);
        expect(password.length >= 8, isTrue);
        expect(PasswordValidator.isValid(password), isFalse);
      });

      test('should reject password missing only number', () {
        final password = 'SecureP@ss';
        expect(PasswordValidator.hasUppercase(password), isTrue);
        expect(PasswordValidator.hasLowercase(password), isTrue);
        expect(PasswordValidator.hasNumber(password), isFalse);
        expect(PasswordValidator.hasSpecialCharacter(password), isTrue);
        expect(password.length >= 8, isTrue);
        expect(PasswordValidator.isValid(password), isFalse);
      });

      test('should reject password missing only special character', () {
        final password = 'SecurePass1';
        expect(PasswordValidator.hasUppercase(password), isTrue);
        expect(PasswordValidator.hasLowercase(password), isTrue);
        expect(PasswordValidator.hasNumber(password), isTrue);
        expect(PasswordValidator.hasSpecialCharacter(password), isFalse);
        expect(password.length >= 8, isTrue);
        expect(PasswordValidator.isValid(password), isFalse);
      });
    });

    group('Validation error messages', () {
      test('should return all errors for weak password', () {
        final errors = PasswordValidator.getValidationErrors('abc');
        expect(errors.length, equals(4)); // missing length, uppercase, number, special
      });

      test('should return empty list for valid password', () {
        final errors = PasswordValidator.getValidationErrors('SecureP@ss1');
        expect(errors, isEmpty);
      });

      test('should include specific error for short password', () {
        final errors = PasswordValidator.getValidationErrors('Aa1@567');
        expect(errors.any((e) => e.contains('8 characters')), isTrue);
      });

      test('should include specific error for missing uppercase', () {
        final errors = PasswordValidator.getValidationErrors('aa1@5678');
        expect(errors.any((e) => e.contains('uppercase')), isTrue);
      });

      test('should include specific error for missing lowercase', () {
        final errors = PasswordValidator.getValidationErrors('AA1@5678');
        expect(errors.any((e) => e.contains('lowercase')), isTrue);
      });

      test('should include specific error for missing number', () {
        final errors = PasswordValidator.getValidationErrors('Aabc@def');
        expect(errors.any((e) => e.contains('number')), isTrue);
      });

      test('should include specific error for missing special character', () {
        final errors = PasswordValidator.getValidationErrors('Aa123456');
        expect(errors.any((e) => e.contains('special character')), isTrue);
      });
    });

    group('Password strength calculation', () {
      test('should return 0 for empty password', () {
        expect(PasswordValidator.getStrength(''), equals(0));
      });

      test('should return low score for weak password', () {
        expect(PasswordValidator.getStrength('abc'), lessThan(50));
      });

      test('should return high score for strong password', () {
        expect(PasswordValidator.getStrength('SecureP@ss1'), greaterThanOrEqualTo(80));
      });

      test('should return 100 for very strong password', () {
        expect(PasswordValidator.getStrength('VerySecureP@ssword123'), equals(100));
      });
    });

    group('Edge cases', () {
      test('should handle password with only special characters', () {
        expect(PasswordValidator.isValid('@@@@@@@@@'), isFalse);
      });

      test('should handle password with unicode characters', () {
        // Unicode characters should not satisfy requirements
        expect(PasswordValidator.hasUppercase('ÄÖÜ'), isFalse);
      });

      test('should handle very long valid password', () {
        final longPassword = 'Aa1@' + 'x' * 100;
        expect(PasswordValidator.isValid(longPassword), isTrue);
      });

      test('should handle password with all requirement types', () {
        expect(PasswordValidator.isValid('aA1!bB2@cC3#'), isFalse); // # is not in special chars
        expect(PasswordValidator.isValid('aA1!bB2@cC3%'), isTrue);
      });
    });
  });
}
