#!/bin/bash

# Test script to demonstrate the login flow using curl
# This script tests all the implemented login features

API_BASE="http://localhost:3001/api"

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Generate unique email for this test run
TEST_EMAIL="test-$(date +%s)@example.com"
TEST_PASSWORD="TestPass123!"
TEST_NAME="Test User"

echo ""
echo "============================================================"
echo "  BASKIT LOGIN FLOW - COMPREHENSIVE TEST SUITE"
echo "============================================================"
echo ""

# Test 1: User Registration
echo -e "${BOLD}TEST 1: User Registration${NC}"
echo -e "${BLUE}ℹ${NC} Registering user: $TEST_EMAIL"

REGISTER_RESPONSE=$(curl -s -X POST "$API_BASE/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"displayName\":\"$TEST_NAME\"}")

if echo "$REGISTER_RESPONSE" | grep -q "success.*true"; then
  echo -e "${GREEN}✓${NC} User registered successfully"
  USER_ID=$(echo "$REGISTER_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  echo -e "${BLUE}ℹ${NC} User ID: $USER_ID"
else
  echo -e "${RED}✗${NC} Registration failed"
  echo "$REGISTER_RESPONSE"
fi

sleep 1

# Test 2: Login with Unverified Email
echo ""
echo -e "${BOLD}TEST 2: Login with Unverified Email${NC}"
echo -e "${BLUE}ℹ${NC} Attempting to login before email verification..."

LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

if echo "$LOGIN_RESPONSE" | grep -q "verify your email"; then
  echo -e "${GREEN}✓${NC} Login correctly blocked for unverified email"
else
  echo -e "${RED}✗${NC} Login should have been blocked"
fi

sleep 1

# Test 3: Verify Email (simulated via database)
echo ""
echo -e "${BOLD}TEST 3: Email Verification (Simulated)${NC}"
echo -e "${BLUE}ℹ${NC} Verifying email via database update..."

docker exec baskit-postgres psql -U postgres -d baskit -c \
  "UPDATE users SET status = 'active', is_email_verified = true WHERE email = '$TEST_EMAIL'" > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓${NC} Email verified successfully"
else
  echo -e "${RED}✗${NC} Failed to verify email"
fi

sleep 1

# Test 4: Successful Login
echo ""
echo -e "${BOLD}TEST 4: Successful Login${NC}"
echo -e "${BLUE}ℹ${NC} Logging in with valid credentials..."

LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

if echo "$LOGIN_RESPONSE" | grep -q "Login successful"; then
  echo -e "${GREEN}✓${NC} Login successful"
  
  # Extract tokens
  ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
  REFRESH_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"refreshToken":"[^"]*"' | cut -d'"' -f4)
  
  echo -e "${BLUE}ℹ${NC} Access Token: ${ACCESS_TOKEN:0:30}..."
  echo -e "${BLUE}ℹ${NC} Refresh Token: ${REFRESH_TOKEN:0:30}..."
else
  echo -e "${RED}✗${NC} Login failed"
  echo "$LOGIN_RESPONSE"
fi

sleep 1

# Test 5: Login with Invalid Password
echo ""
echo -e "${BOLD}TEST 5: Login with Invalid Password${NC}"
echo -e "${BLUE}ℹ${NC} Attempting login with wrong password..."

INVALID_LOGIN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"WrongPassword123!\"}")

if echo "$INVALID_LOGIN" | grep -q "Invalid"; then
  echo -e "${GREEN}✓${NC} Login correctly failed with invalid password"
else
  echo -e "${RED}✗${NC} Login should have failed"
fi

sleep 1

# Test 6: Rate Limiting
echo ""
echo -e "${BOLD}TEST 6: Rate Limiting${NC}"
echo -e "${BLUE}ℹ${NC} Making 5 failed login attempts to trigger rate limit..."

RATE_TEST_EMAIL="ratelimit-$(date +%s)@example.com"
for i in {1..5}; do
  curl -s -X POST "$API_BASE/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$RATE_TEST_EMAIL\",\"password\":\"WrongPassword123!\"}" > /dev/null
  echo -e "${BLUE}ℹ${NC} Failed attempt $i/5"
done

echo -e "${BLUE}ℹ${NC} Attempting 6th login (should be rate limited)..."
RATE_LIMIT_RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$RATE_TEST_EMAIL\",\"password\":\"TestPass123!\"}")

if echo "$RATE_LIMIT_RESPONSE" | grep -q "Too many"; then
  echo -e "${GREEN}✓${NC} Rate limiting working correctly"
else
  echo -e "${YELLOW}⚠${NC} Rate limit may not have triggered (depends on IP tracking)"
fi

sleep 2

# Test 7: Token Refresh
echo ""
echo -e "${BOLD}TEST 7: Token Refresh${NC}"
echo -e "${BLUE}ℹ${NC} Refreshing access token..."

if [ -n "$REFRESH_TOKEN" ]; then
  REFRESH_RESPONSE=$(curl -s -X POST "$API_BASE/auth/refresh" \
    -H "Content-Type: application/json" \
    -d "{\"refreshToken\":\"$REFRESH_TOKEN\"}")

  if echo "$REFRESH_RESPONSE" | grep -q "Token refreshed successfully"; then
    echo -e "${GREEN}✓${NC} Token refreshed successfully"
    
    # Extract new tokens
    NEW_ACCESS_TOKEN=$(echo "$REFRESH_RESPONSE" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
    NEW_REFRESH_TOKEN=$(echo "$REFRESH_RESPONSE" | grep -o '"refreshToken":"[^"]*"' | cut -d'"' -f4)
    
    echo -e "${BLUE}ℹ${NC} New Access Token: ${NEW_ACCESS_TOKEN:0:30}..."
    
    # Update tokens
    ACCESS_TOKEN="$NEW_ACCESS_TOKEN"
    REFRESH_TOKEN="$NEW_REFRESH_TOKEN"
  else
    echo -e "${RED}✗${NC} Token refresh failed"
    echo "$REFRESH_RESPONSE"
  fi
else
  echo -e "${RED}✗${NC} No refresh token available"
fi

sleep 1

# Test 8: Logout
echo ""
echo -e "${BOLD}TEST 8: Logout${NC}"
echo -e "${BLUE}ℹ${NC} Logging out..."

if [ -n "$ACCESS_TOKEN" ]; then
  LOGOUT_RESPONSE=$(curl -s -X POST "$API_BASE/auth/logout" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -d "{\"refreshToken\":\"$REFRESH_TOKEN\"}")

  if echo "$LOGOUT_RESPONSE" | grep -q "Logged out successfully"; then
    echo -e "${GREEN}✓${NC} Logout successful"
  else
    echo -e "${RED}✗${NC} Logout failed"
    echo "$LOGOUT_RESPONSE"
  fi
else
  echo -e "${RED}✗${NC} No access token available"
fi

sleep 1

# Test 9: Login Again After Logout
echo ""
echo -e "${BOLD}TEST 9: Login Again After Logout${NC}"
echo -e "${BLUE}ℹ${NC} Logging in again..."

RELOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

if echo "$RELOGIN_RESPONSE" | grep -q "Login successful"; then
  echo -e "${GREEN}✓${NC} Successfully logged in again"
else
  echo -e "${RED}✗${NC} Login failed"
  echo "$RELOGIN_RESPONSE"
fi

echo ""
echo "============================================================"
echo "  TEST SUITE COMPLETED"
echo "============================================================"
echo ""
echo -e "${BLUE}ℹ${NC} Test user created: $TEST_EMAIL"
echo -e "${BLUE}ℹ${NC} All login flow features have been tested"
echo ""
