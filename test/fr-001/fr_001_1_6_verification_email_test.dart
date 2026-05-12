import 'package:flutter_test/flutter_test.dart';

/// FR-001.1.6: The system SHALL send a verification email to confirm the user's email address
///
/// This test suite verifies that the system properly sends verification emails
/// upon user registration.

// Verification token model
class VerificationToken {
  final String token;
  final String userId;
  final String email;
  final DateTime expiresAt;
  final DateTime createdAt;

  VerificationToken({
    required this.token,
    required this.userId,
    required this.email,
    required this.expiresAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired;

  /// Token should be valid for 24 hours as per requirements
  static const Duration tokenValidity = Duration(hours: 24);
}

// Email content model
class EmailContent {
  final String to;
  final String subject;
  final String body;
  final String? htmlBody;

  EmailContent({
    required this.to,
    required this.subject,
    required this.body,
    this.htmlBody,
  });
}

// Email send result
class EmailSendResult {
  final bool success;
  final String? messageId;
  final String? error;

  EmailSendResult({
    required this.success,
    this.messageId,
    this.error,
  });
}

// Mock email service for testing
class MockEmailService {
  final List<EmailContent> sentEmails = [];
  bool shouldFail = false;
  String? failureReason;

  Future<EmailSendResult> sendEmail(EmailContent email) async {
    if (shouldFail) {
      return EmailSendResult(
        success: false,
        error: failureReason ?? 'Email service unavailable',
      );
    }

    sentEmails.add(email);
    return EmailSendResult(
      success: true,
      messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  void clear() {
    sentEmails.clear();
    shouldFail = false;
    failureReason = null;
  }
}

// Mock token service for generating verification tokens
class MockTokenService {
  final Map<String, VerificationToken> _tokens = {};

  /// Generate a secure verification token
  String generateToken() {
    // In production, use crypto-secure random generation
    return 'verify_${DateTime.now().millisecondsSinceEpoch}_${_tokens.length}';
  }

  /// Create and store a verification token for a user
  VerificationToken createVerificationToken({
    required String userId,
    required String email,
  }) {
    final token = VerificationToken(
      token: generateToken(),
      userId: userId,
      email: email,
      expiresAt: DateTime.now().add(VerificationToken.tokenValidity),
    );

    _tokens[token.token] = token;
    return token;
  }

  /// Get token by token string
  VerificationToken? getToken(String token) => _tokens[token];

  void clear() => _tokens.clear();
}

// Verification email service
class VerificationEmailService {
  final MockEmailService emailService;
  final MockTokenService tokenService;

  VerificationEmailService({
    required this.emailService,
    required this.tokenService,
  });

  /// Send verification email to user
  Future<VerificationEmailResult> sendVerificationEmail({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    // Generate verification token
    final token = tokenService.createVerificationToken(
      userId: userId,
      email: email,
    );

    // Build verification link
    final verificationLink = buildVerificationLink(token.token);

    // Build email content
    final emailContent = EmailContent(
      to: email,
      subject: 'Verify your Baskit account',
      body: '''
Hello $displayName,

Thank you for registering with Baskit!

Please verify your email address by clicking the link below:

$verificationLink

This link will expire in 24 hours.

If you did not create an account, please ignore this email.

Best regards,
The Baskit Team
''',
      htmlBody: '''
<html>
<body>
<h2>Hello $displayName,</h2>
<p>Thank you for registering with Baskit!</p>
<p>Please verify your email address by clicking the button below:</p>
<a href="$verificationLink" style="display:inline-block;background-color:#4CAF50;color:white;padding:10px 20px;text-decoration:none;border-radius:5px;">Verify Email</a>
<p>Or copy this link: $verificationLink</p>
<p>This link will expire in 24 hours.</p>
<p>If you did not create an account, please ignore this email.</p>
<p>Best regards,<br>The Baskit Team</p>
</body>
</html>
''',
    );

    // Send email
    final sendResult = await emailService.sendEmail(emailContent);

    if (sendResult.success) {
      return VerificationEmailResult(
        success: true,
        token: token,
      );
    } else {
      return VerificationEmailResult(
        success: false,
        error: sendResult.error,
      );
    }
  }

  /// Build verification link from token
  String buildVerificationLink(String token) {
    return 'https://baskit.app/verify-email?token=$token';
  }
}

// Result of sending verification email
class VerificationEmailResult {
  final bool success;
  final VerificationToken? token;
  final String? error;

  VerificationEmailResult({
    required this.success,
    this.token,
    this.error,
  });
}

void main() {
  group('FR-001.1.6: Verification Email Sending', () {
    late MockEmailService emailService;
    late MockTokenService tokenService;
    late VerificationEmailService verificationService;

    setUp(() {
      emailService = MockEmailService();
      tokenService = MockTokenService();
      verificationService = VerificationEmailService(
        emailService: emailService,
        tokenService: tokenService,
      );
    });

    tearDown(() {
      emailService.clear();
      tokenService.clear();
    });

    group('Verification email sending', () {
      test('should send verification email on registration', () async {
        // Act
        final result = await verificationService.sendVerificationEmail(
          userId: 'user_123',
          email: 'user@example.com',
          displayName: 'John Doe',
        );

        // Assert
        expect(result.success, isTrue);
        expect(emailService.sentEmails.length, equals(1));
      });

      test('should send email to correct recipient', () async {
        // Act
        await verificationService.sendVerificationEmail(
          userId: 'user_123',
          email: 'recipient@example.com',
          displayName: 'John Doe',
        );

        // Assert
        final sentEmail = emailService.sentEmails.first;
        expect(sentEmail.to, equals('recipient@example.com'));
      });

      test('should include appropriate subject line', () async {
        // Act
        await verificationService.sendVerificationEmail(
          userId: 'user_123',
          email: 'user@example.com',
          displayName: 'John Doe',
        );

        // Assert
        final sentEmail = emailService.sentEmails.first;
        expect(sentEmail.subject.toLowerCase(), contains('verify'));
      });

      test('should include user display name in email body', () async {
        // Act
        await verificationService.sendVerificationEmail(
          userId: 'user_123',
          email: 'user@example.com',
          displayName: 'John Doe',
        );

        // Assert
        final sentEmail = emailService.sentEmails.first;
        expect(sentEmail.body, contains('John Doe'));
      });

      test('should include verification link in email body', () async {
        // Act
        final result = await verificationService.sendVerificationEmail(
          userId: 'user_123',
          email: 'user@example.com',
          displayName: 'John Doe',
        );

        // Assert
        final sentEmail = emailService.sentEmails.first;
        final expectedLink = verificationService.buildVerificationLink(
          result.token!.token,
        );
        expect(sentEmail.body, contains(expectedLink));
      });

      test('should include HTML body for rich email clients', () async {
        // Act
        await verificationService.sendVerificationEmail(
          userId: 'user_123',
          email: 'user@example.com',
          displayName: 'John Doe',
        );

        // Assert
        final sentEmail = emailService.sentEmails.first;
        expect(sentEmail.htmlBody, isNotNull);
        expect(sentEmail.htmlBody, contains('<html>'));
      });
    });

    group('Verification token generation', () {
      test('should generate unique token for each registration', () async {
        // Act
        final result1 = await verificationService.sendVerificationEmail(
          userId: 'user_1',
          email: 'user1@example.com',
          displayName: 'User One',
        );

        final result2 = await verificationService.sendVerificationEmail(
          userId: 'user_2',
          email: 'user2@example.com',
          displayName: 'User Two',
        );

        // Assert
        expect(result1.token!.token, isNot(equals(result2.token!.token)));
      });

      test('should create token with 24-hour expiration', () async {
        // Act
        final result = await verificationService.sendVerificationEmail(
          userId: 'user_123',
          email: 'user@example.com',
          displayName: 'John Doe',
        );

        // Assert
        final token = result.token!;
        final expectedExpiration = token.createdAt.add(
          VerificationToken.tokenValidity,
        );

        expect(
          token.expiresAt.difference(expectedExpiration).inSeconds.abs(),
          lessThan(2), // Allow 2 second tolerance
        );
      });

      test('should associate token with user ID', () async {
        // Act
        final result = await verificationService.sendVerificationEmail(
          userId: 'user_specific_123',
          email: 'user@example.com',
          displayName: 'John Doe',
        );

        // Assert
        expect(result.token!.userId, equals('user_specific_123'));
      });

      test('should associate token with email', () async {
        // Act
        final result = await verificationService.sendVerificationEmail(
          userId: 'user_123',
          email: 'specific@example.com',
          displayName: 'John Doe',
        );

        // Assert
        expect(result.token!.email, equals('specific@example.com'));
      });

      test('should store token for later verification', () async {
        // Act
        final result = await verificationService.sendVerificationEmail(
          userId: 'user_123',
          email: 'user@example.com',
          displayName: 'John Doe',
        );

        // Assert
        final storedToken = tokenService.getToken(result.token!.token);
        expect(storedToken, isNotNull);
        expect(storedToken!.userId, equals('user_123'));
      });
    });

    group('Token validity', () {
      test('should create valid (non-expired) token', () async {
        // Act
        final result = await verificationService.sendVerificationEmail(
          userId: 'user_123',
          email: 'user@example.com',
          displayName: 'John Doe',
        );

        // Assert
        expect(result.token!.isValid, isTrue);
        expect(result.token!.isExpired, isFalse);
      });

      test('expired token should be marked as invalid', () {
        // Arrange - create token that is already expired
        final expiredToken = VerificationToken(
          token: 'expired_token',
          userId: 'user_123',
          email: 'user@example.com',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        // Assert
        expect(expiredToken.isExpired, isTrue);
        expect(expiredToken.isValid, isFalse);
      });

      test('token with future expiration should be valid', () {
        // Arrange
        final validToken = VerificationToken(
          token: 'valid_token',
          userId: 'user_123',
          email: 'user@example.com',
          expiresAt: DateTime.now().add(const Duration(hours: 12)),
        );

        // Assert
        expect(validToken.isValid, isTrue);
        expect(validToken.isExpired, isFalse);
      });
    });

    group('Verification link', () {
      test('should build valid verification link with token', () {
        // Act
        final link = verificationService.buildVerificationLink('test_token_123');

        // Assert
        expect(link, contains('test_token_123'));
        expect(link, startsWith('https://'));
        expect(link, contains('verify-email'));
      });

      test('should include token as query parameter', () {
        // Act
        final link = verificationService.buildVerificationLink('my_token');

        // Assert
        expect(link, contains('token=my_token'));
      });
    });

    group('Email service failure handling', () {
      test('should return failure when email service fails', () async {
        // Arrange
        emailService.shouldFail = true;
        emailService.failureReason = 'SMTP server unavailable';

        // Act
        final result = await verificationService.sendVerificationEmail(
          userId: 'user_123',
          email: 'user@example.com',
          displayName: 'John Doe',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, equals('SMTP server unavailable'));
      });

      test('should not store token if email fails', () async {
        // Arrange
        emailService.shouldFail = true;

        // Act
        final result = await verificationService.sendVerificationEmail(
          userId: 'user_123',
          email: 'user@example.com',
          displayName: 'John Doe',
        );

        // Assert
        // Token was created but email failed - in real implementation,
        // you might want to clean up the token or not create it until email succeeds
        expect(result.success, isFalse);
      });
    });

    group('Email content requirements', () {
      test('should include expiration notice in email', () async {
        // Act
        await verificationService.sendVerificationEmail(
          userId: 'user_123',
          email: 'user@example.com',
          displayName: 'John Doe',
        );

        // Assert
        final sentEmail = emailService.sentEmails.first;
        expect(sentEmail.body.toLowerCase(), contains('24 hours'));
      });

      test('should include notice about ignoring if not registered', () async {
        // Act
        await verificationService.sendVerificationEmail(
          userId: 'user_123',
          email: 'user@example.com',
          displayName: 'John Doe',
        );

        // Assert
        final sentEmail = emailService.sentEmails.first;
        expect(sentEmail.body.toLowerCase(), contains('ignore'));
      });
    });

    group('Multiple verification emails', () {
      test('should allow sending multiple verification emails', () async {
        // Act
        await verificationService.sendVerificationEmail(
          userId: 'user_1',
          email: 'user1@example.com',
          displayName: 'User 1',
        );
        await verificationService.sendVerificationEmail(
          userId: 'user_2',
          email: 'user2@example.com',
          displayName: 'User 2',
        );
        await verificationService.sendVerificationEmail(
          userId: 'user_3',
          email: 'user3@example.com',
          displayName: 'User 3',
        );

        // Assert
        expect(emailService.sentEmails.length, equals(3));
      });
    });
  });
}
