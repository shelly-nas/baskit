const { hashPassword, verifyPassword, isPasswordReused, SALT_ROUNDS } = require('../../src/services/password.service');
const bcrypt = require('bcryptjs');

describe('Password Service', () => {
  describe('FR-001.1.8: Password hashing with bcrypt (cost factor 12)', () => {
    test('should hash password using bcrypt with cost factor 12', async () => {
      const password = 'SecurePass123!';
      const hashedPassword = await hashPassword(password);

      expect(hashedPassword).toBeDefined();
      expect(hashedPassword).not.toBe(password);
      expect(typeof hashedPassword).toBe('string');
      
      // Verify it's a bcrypt hash
      expect(hashedPassword.startsWith('$2a$') || hashedPassword.startsWith('$2b$')).toBe(true);
    });

    test('should use salt rounds of 12', () => {
      expect(SALT_ROUNDS).toBe(12);
    });

    test('should generate different hashes for same password', async () => {
      const password = 'SecurePass123!';
      const hash1 = await hashPassword(password);
      const hash2 = await hashPassword(password);

      expect(hash1).not.toBe(hash2);
    });

    test('should verify cost factor in generated hash', async () => {
      const password = 'SecurePass123!';
      const hashedPassword = await hashPassword(password);
      
      // Extract cost factor from bcrypt hash (format: $2a$12$...)
      const costFactor = parseInt(hashedPassword.split('$')[2]);
      expect(costFactor).toBe(12);
    });

    test('should handle special characters in password', async () => {
      const passwords = [
        'Test!@#$%^&*()123',
        'Pass<>?:"{}|word1',
        'Secure+=_-[]\\;\',./',
      ];

      for (const password of passwords) {
        const hashedPassword = await hashPassword(password);
        expect(hashedPassword).toBeDefined();
        const isValid = await bcrypt.compare(password, hashedPassword);
        expect(isValid).toBe(true);
      }
    });

    test('should handle long passwords', async () => {
      const longPassword = 'SecurePass123!' + 'A'.repeat(100);
      const hashedPassword = await hashPassword(longPassword);
      
      expect(hashedPassword).toBeDefined();
      const isValid = await bcrypt.compare(longPassword, hashedPassword);
      expect(isValid).toBe(true);
    });

    test('should handle unicode characters in password', async () => {
      const unicodePasswords = [
        'Pässwörd123!',
        '密码Test123!',
        'Contraseña1!',
      ];

      for (const password of unicodePasswords) {
        const hashedPassword = await hashPassword(password);
        expect(hashedPassword).toBeDefined();
        const isValid = await bcrypt.compare(password, hashedPassword);
        expect(isValid).toBe(true);
      }
    });
  });

  describe('Password Verification', () => {
    test('should verify correct password', async () => {
      const password = 'SecurePass123!';
      const hashedPassword = await hashPassword(password);
      
      const isMatch = await verifyPassword(password, hashedPassword);
      expect(isMatch).toBe(true);
    });

    test('should reject incorrect password', async () => {
      const password = 'SecurePass123!';
      const wrongPassword = 'WrongPass123!';
      const hashedPassword = await hashPassword(password);
      
      const isMatch = await verifyPassword(wrongPassword, hashedPassword);
      expect(isMatch).toBe(false);
    });

    test('should be case-sensitive', async () => {
      const password = 'SecurePass123!';
      const hashedPassword = await hashPassword(password);
      
      const isMatch = await verifyPassword('securepass123!', hashedPassword);
      expect(isMatch).toBe(false);
    });

    test('should handle empty password verification', async () => {
      const password = 'SecurePass123!';
      const hashedPassword = await hashPassword(password);
      
      const isMatch = await verifyPassword('', hashedPassword);
      expect(isMatch).toBe(false);
    });
  });

  describe('Password Reuse Prevention', () => {
    test('should detect password reuse', async () => {
      const password = 'SecurePass123!';
      const oldHashes = [
        await hashPassword('OldPass1!'),
        await hashPassword(password),
        await hashPassword('OldPass2!'),
      ];

      const isReused = await isPasswordReused(password, oldHashes);
      expect(isReused).toBe(true);
    });

    test('should allow new password not in history', async () => {
      const newPassword = 'NewSecurePass123!';
      const oldHashes = [
        await hashPassword('OldPass1!'),
        await hashPassword('OldPass2!'),
        await hashPassword('OldPass3!'),
      ];

      const isReused = await isPasswordReused(newPassword, oldHashes);
      expect(isReused).toBe(false);
    });

    test('should handle empty password history', async () => {
      const password = 'SecurePass123!';
      const oldHashes = [];

      const isReused = await isPasswordReused(password, oldHashes);
      expect(isReused).toBe(false);
    });
  });

  describe('Error Handling', () => {
    test('should handle null password gracefully', async () => {
      await expect(hashPassword(null)).rejects.toThrow();
    });

    test('should handle undefined password gracefully', async () => {
      await expect(hashPassword(undefined)).rejects.toThrow();
    });

    test('should handle invalid hash format in verification', async () => {
      const password = 'SecurePass123!';
      const invalidHash = 'not-a-valid-hash';

      await expect(verifyPassword(password, invalidHash)).rejects.toThrow();
    });
  });

  describe('Performance', () => {
    test('should hash password in reasonable time', async () => {
      const password = 'SecurePass123!';
      const startTime = Date.now();
      
      await hashPassword(password);
      
      const duration = Date.now() - startTime;
      // With cost factor 12, should take less than 500ms
      expect(duration).toBeLessThan(500);
    });
  });
});
