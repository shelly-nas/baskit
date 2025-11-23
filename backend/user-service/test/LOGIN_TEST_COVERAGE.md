# Login Requirements Test Coverage

## Overview

Comprehensive test suite for login functionality requirements (FR-001.2.x).

## Test Files Created

### 1. Integration Tests: `login-requirements.test.js`

**Location:** `/backend/user-service/test/integration/login-requirements.test.js`

Full end-to-end testing of login functionality with database and service integration.

#### Requirements Coverage

##### FR-001.2.1: Email and Password Login Functionality

- ✅ Successfully authenticate with valid email and password
- ✅ Reject login with incorrect email
- ✅ Reject login with incorrect password
- ✅ Require both email and password fields
- ✅ Validate email format

##### FR-001.2.2: Rate Limiting (5 attempts per 15 minutes per IP)

- ✅ Allow up to 5 failed login attempts from same IP
- ✅ Block 6th failed login attempt from same IP
- ✅ Enforce rate limit per IP address
- ✅ Reset rate limit after successful login within limit

##### FR-001.2.3: Account Locking (10 consecutive failed attempts)

- ✅ Lock account after exactly 10 failed login attempts
- ✅ Prevent login when account is locked even with correct password
- ✅ Include lock duration in error message
- ✅ Reset failed attempts counter on successful login
- ✅ Increment failed attempts counter on each failed login

##### FR-001.2.4: JWT Access Tokens (24-hour expiration)

- ✅ Return JWT access token on successful login
- ✅ Generate access token with 24-hour expiration
- ✅ Include user information in JWT payload
- ✅ Use HS256 algorithm for JWT signing
- ✅ Include issuer and audience in JWT claims

##### FR-001.2.5: Refresh Tokens (30-day expiration)

- ✅ Return refresh token on successful login
- ✅ Generate refresh token with 30-day expiration
- ✅ Mark refresh token as type "refresh"
- ✅ Allow token refresh with valid refresh token
- ✅ Issue new access and refresh tokens on refresh
- ✅ Reject invalid refresh token

##### FR-001.2.6: "Remember Me" Functionality (30-day session)

- ✅ Accept rememberMe parameter on login
- ✅ Extend access token to 30 days when rememberMe is true
- ✅ Use 24h expiration when rememberMe is false
- ✅ Use 24h expiration when rememberMe is not provided
- ✅ Create session with 30-day expiration when rememberMe is true
- ✅ Create session with 24-hour expiration when rememberMe is false

##### FR-001.2.7: Login Attempt Logging (Security Auditing)

- ✅ Log successful login attempts
- ✅ Log failed login attempts
- ✅ Include IP address in audit logs
- ✅ Include timestamp in audit logs
- ✅ Log all failed attempts with email in description
- ✅ Log account locking events
- ✅ Maintain audit trail for security analysis

##### FR-001.2.8: Prevent Login for Unverified Accounts

- ✅ Reject login for unverified email accounts
- ✅ Allow login for verified email accounts
- ✅ Check email verification before password validation
- ✅ Prevent unverified accounts even with correct credentials
- ✅ Not increment failed attempts for unverified accounts
- ✅ Log unverified login attempts

#### Integration Tests

- ✅ Enforce all security measures in correct order
- ✅ Provide complete login response with all required data

**Total Integration Tests:** 50+

---

### 2. Unit Tests: `jwt.service.test.js`

**Location:** `/backend/user-service/test/unit/jwt.service.test.js`

Isolated testing of JWT token generation and validation logic.

#### Test Suites

##### FR-001.2.4: Access Token Generation

- ✅ Generate valid JWT access token
- ✅ Generate access token with 24-hour expiration by default
- ✅ Include user information in token payload
- ✅ Mark token as type "access"
- ✅ Include standard JWT claims
- ✅ Use HS256 algorithm
- ✅ Allow custom expiration time
- ✅ Default role to "user" if not provided

##### FR-001.2.5: Refresh Token Generation

- ✅ Generate valid JWT refresh token
- ✅ Generate refresh token with 30-day expiration by default
- ✅ Include user information in refresh token payload
- ✅ Mark token as type "refresh"
- ✅ Include unique token ID for rotation
- ✅ Not include role in refresh token

##### FR-001.2.6: Remember Me Functionality

- ✅ Extend refresh token to 30 days when rememberMe is true
- ✅ Use default 30 days when rememberMe is false
- ✅ Generate token pair with remember me option
- ✅ Generate token pair without remember me
- ✅ Default to 24h expiration when rememberMe not specified

##### Token Verification and Validation

- ✅ Verify valid access token
- ✅ Verify valid refresh token
- ✅ Reject token with mismatched type
- ✅ Reject invalid token
- ✅ Reject expired token
- ✅ Validate issuer and audience

##### Token Utility Functions

- ✅ Decode token without verification
- ✅ Get token expiration time
- ✅ Detect expired token
- ✅ Detect valid token as not expired
- ✅ Extract user ID from token
- ✅ Return null for invalid token extraction

##### Token Pair Generation

- ✅ Generate both access and refresh tokens
- ✅ Generate different access and refresh tokens
- ✅ Use user data for both tokens

##### Security Considerations

- ✅ Generate unique tokens for same user
- ✅ Generate unique refresh token IDs
- ✅ Use secure signing algorithm
- ✅ Not include sensitive data in token

##### Error Handling

- ✅ Handle malformed tokens gracefully
- ✅ Handle null token
- ✅ Handle undefined token
- ✅ Handle empty string token

##### Configuration

- ✅ Use correct default expiration times
- ✅ Respect environment configuration

**Total Unit Tests:** 45+

---

## Test Execution

### Prerequisites

**Important:** All integration tests require Docker services to be running:

```bash
# Start Docker services from project root
cd /Users/jelle/Documents/GitHub/baskit
docker compose up -d
```

### Run All Tests

```bash
cd backend/user-service
npm test
```

### Run Integration Tests Only

```bash
npm run test:integration
```

### Run Unit Tests Only

```bash
npm run test:unit
```

### Run Specific Test File

```bash
# Integration tests (requires Docker)
npx jest test/integration/login-requirements.test.js

# Unit tests
npx jest test/unit/jwt.service.test.js
```

### Run with Coverage

```bash
npm test -- --coverage
```

### Using the Test Script

```bash
# Run the full login flow integration test
cd backend/user-service
chmod +x test-login-flow.sh
./test-login-flow.sh
```

---

## Requirements Traceability Matrix

| Requirement                      | Integration Tests | Unit Tests | Status   |
| -------------------------------- | ----------------- | ---------- | -------- |
| FR-001.2.1: Email/Password Login | ✅ 5 tests        | -          | Complete |
| FR-001.2.2: Rate Limiting        | ✅ 4 tests        | -          | Complete |
| FR-001.2.3: Account Locking      | ✅ 5 tests        | -          | Complete |
| FR-001.2.4: JWT 24h Token        | ✅ 5 tests        | ✅ 8 tests | Complete |
| FR-001.2.5: Refresh Token 30d    | ✅ 6 tests        | ✅ 6 tests | Complete |
| FR-001.2.6: Remember Me          | ✅ 6 tests        | ✅ 5 tests | Complete |
| FR-001.2.7: Audit Logging        | ✅ 7 tests        | -          | Complete |
| FR-001.2.8: Unverified Block     | ✅ 6 tests        | -          | Complete |

**Total Test Cases: 95+**

---

## Test Data Requirements

### Database Setup

- Test database connection via `database.connect()`
- Test users created with `is_email_verified = true`
- Automatic cleanup after each test

### Required Tables

- `users` - User authentication data
- `user_sessions` - Active sessions
- `audit_logs` - Security audit trail

### Test User Credentials

- Email: `loginreq@example.com`
- Password: `SecurePass123!`
- Status: `active`
- Email Verified: `true`

---

## Test Coverage Goals

### Code Coverage Targets

- **Lines:** ≥ 80%
- **Branches:** ≥ 80%
- **Functions:** ≥ 80%
- **Statements:** ≥ 80%

### Coverage Areas

1. **Authentication Flow:** Complete login process
2. **Security Measures:** Rate limiting, account locking
3. **Token Management:** JWT generation and validation
4. **Error Scenarios:** Invalid credentials, locked accounts
5. **Audit Trail:** Logging successful and failed attempts
6. **Email Verification:** Blocking unverified accounts

---

## Dependencies

### Testing Frameworks

- **Jest:** Test runner and assertion library
- **Supertest:** HTTP request testing
- **jsonwebtoken:** JWT token manipulation

### Services Tested

- `auth.controller.js` - Authentication endpoints
- `jwt.service.js` - Token generation
- `password.service.js` - Password validation
- `rateLimit.service.js` - Rate limiting
- Database layer - User and session management

---

## Test Maintenance

### When to Update Tests

1. **New Login Requirements:** Add new test cases
2. **Security Policy Changes:** Update rate limiting/locking tests
3. **Token Expiration Changes:** Adjust JWT verification tests
4. **Database Schema Updates:** Update test data setup

### Best Practices

- ✅ Clean up test data after each test
- ✅ Clear rate limits before each test
- ✅ Use realistic test data
- ✅ Test both success and failure paths
- ✅ Verify database state changes
- ✅ Check audit log entries

---

## Known Issues / Limitations

### Test Environment

- Tests use in-memory or test database
- Rate limiting uses test implementation
- Email sending is mocked (not tested here)

### Future Enhancements

- [ ] Add load testing for rate limiting
- [ ] Test concurrent login attempts
- [ ] Add tests for token rotation
- [ ] Test IP address detection edge cases
- [ ] Add performance benchmarks

---

## References

### Functional Requirements

- `docs/features/FR-001.md` - User Registration and Login Requirements
- `backend/user-service/LOGIN_IMPLEMENTATION.md` - Implementation details
- `backend/user-service/LOGIN_SUMMARY.md` - Feature summary

### Related Tests

- `test/integration/login.test.js` - Original login tests
- `test/integration/registration.test.js` - Registration flow tests
- `test/unit/password.service.test.js` - Password hashing tests
- `test/unit/token.service.test.js` - Verification token tests

---

**Last Updated:** November 23, 2025  
**Test Suite Version:** 1.0.0  
**Maintainer:** Baskit Development Team
