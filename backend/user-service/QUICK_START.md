# Quick Start Guide - User Registration Feature

## Prerequisites

1. **Node.js** (v16 or higher)
2. **PostgreSQL** (v14 or higher)
3. **Docker & Docker Compose** (optional, for easy database setup)

## Step 1: Database Setup

### Option A: Using Docker Compose (Recommended)

```bash
# Start PostgreSQL database
docker-compose up -d postgres

# Wait a few seconds for database to be ready
sleep 5
```

### Option B: Local PostgreSQL

Make sure PostgreSQL is running and create the database:

```bash
psql -U postgres -c "CREATE DATABASE baskit;"
```

## Step 2: Run Database Migrations

```bash
cd database

# Install dependencies if not already done
npm install

# Run migrations to create all tables
npm run migrate

# (Optional) Seed initial data
npm run seed
```

Expected output:

```
✓ Running migration: 00_migrations.sql
✓ Running migration: 01_user_service.sql
✓ Running migration: 07_verification_tokens.sql
...
✅ All migrations completed successfully
```

## Step 3: Configure User Service

```bash
cd ../backend/user-service

# Install dependencies
npm install

# Create .env file from example
cp .env.example .env

# Edit .env if needed (default values should work for local development)
```

## Step 4: Start User Service

```bash
# Development mode with auto-reload
npm run dev

# OR production mode
npm start
```

Expected output:

```
[INFO] Database connection established successfully
[INFO] User Service running on port 3001
[INFO] Environment: development
```

## Step 5: Test the Registration Feature

### Test 1: Register a New User

```bash
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!",
    "displayName": "Test User"
  }'
```

**Expected Response** (201 Created):

```json
{
  "success": true,
  "message": "Registration successful. Please check your email to verify your account.",
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "test@example.com",
      "displayName": "Test User",
      "status": "pending_verification",
      "createdAt": "2025-11-23T10:30:00.000Z"
    }
  }
}
```

### Test 2: Check Verification Email

Since email is currently mocked, check the console logs for the verification token:

```
[INFO] Verification email sent {
  to: 'test@example.com',
  subject: 'Verify your Baskit account',
  verificationUrl: 'http://localhost:3000/verify-email?token=abc123...'
}
```

### Test 3: Verify Email

Copy the token from the logs and verify the email:

```bash
curl -X POST http://localhost:3001/api/auth/verify-email \
  -H "Content-Type: application/json" \
  -d '{
    "token": "PASTE_TOKEN_HERE"
  }'
```

**Expected Response** (200 OK):

```json
{
  "success": true,
  "message": "Email verified successfully. You can now log in."
}
```

### Test 4: Verify in Database

```bash
# Connect to database
docker exec -it baskit-postgres psql -U postgres -d baskit

# Or if using local PostgreSQL
psql -U postgres -d baskit
```

Run these queries:

```sql
-- Check the registered user
SELECT id, email, display_name, status, is_email_verified, created_at
FROM users
WHERE email = 'test@example.com';

-- Check verification token
SELECT vt.token_type, vt.expires_at, vt.used_at, u.email
FROM verification_tokens vt
JOIN users u ON vt.user_id = u.id
WHERE u.email = 'test@example.com';

-- Check audit logs
SELECT event_type, event_description, ip_address, created_at
FROM audit_logs
ORDER BY created_at DESC
LIMIT 5;
```

## Test Error Handling

### Invalid Email Format

```bash
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "not-an-email",
    "password": "SecurePass123!",
    "displayName": "Test User"
  }'
```

Expected: `400 Bad Request - "Please enter a valid email address"`

### Weak Password

```bash
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test2@example.com",
    "password": "weak",
    "displayName": "Test User"
  }'
```

Expected: `400 Bad Request - "Password must meet complexity requirements"`

### Short Display Name

```bash
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test3@example.com",
    "password": "SecurePass123!",
    "displayName": "A"
  }'
```

Expected: `400 Bad Request - "Name must be between 2 and 50 characters"`

### Duplicate Email

Try registering the same email twice:

```bash
# First registration
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "duplicate@example.com",
    "password": "SecurePass123!",
    "displayName": "First User"
  }'

# Second registration with same email
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "duplicate@example.com",
    "password": "SecurePass123!",
    "displayName": "Second User"
  }'
```

Expected second response: `409 Conflict - "An account with this email already exists"`

## Troubleshooting

### Issue: "Failed to connect to database"

**Solution**:

1. Verify PostgreSQL is running: `docker ps` or `pg_isready`
2. Check database credentials in `.env`
3. Ensure database exists: `psql -U postgres -l`

### Issue: "Table does not exist"

**Solution**:

```bash
cd database
npm run migrate
```

### Issue: "Port 3001 already in use"

**Solution**:

1. Change PORT in `.env` to different value (e.g., 3002)
2. Or stop the process using port 3001

### Issue: "Module not found"

**Solution**:

```bash
cd backend/user-service
npm install

cd ../shared
npm install
```

## Health Check

Verify the service is running:

```bash
curl http://localhost:3001/api/health
```

Expected response:

```json
{
  "status": "healthy",
  "service": "user-service",
  "timestamp": "2025-11-23T10:30:00.000Z"
}
```

## Next Steps

1. ✅ User registration is working
2. ➡️ Implement login functionality (FR-001.2)
3. ➡️ Add rate limiting
4. ➡️ Integrate real email service (SendGrid/AWS SES)
5. ➡️ Add comprehensive tests

## Additional Resources

- **Detailed Documentation**: `REGISTRATION_IMPLEMENTATION.md`
- **Implementation Summary**: `IMPLEMENTATION_SUMMARY.md`
- **Feature Requirements**: `../../docs/features/FR-001.md`
- **API Reference**: See route files in `src/routes/`

## Support

For issues or questions:

1. Check the troubleshooting section above
2. Review logs in the console
3. Check database state with SQL queries
4. Verify all environment variables are set correctly

---

**Quick Start Complete!** 🎉

You now have a fully functional user registration system with:

- ✅ Email validation
- ✅ Password complexity enforcement
- ✅ Display name validation
- ✅ Email verification
- ✅ Secure password storage (bcrypt)
- ✅ Audit logging
- ✅ Comprehensive error handling
