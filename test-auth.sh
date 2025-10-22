#!/bin/bash

# Test authentication methods for the API
# This script helps test different authentication approaches with Authelia

API_URL="${1:-https://api-images.quickstark.com}"
ENDPOINT="${2:-/images?backend=mongo}"
USERNAME="${3:-djn12313}"
PASSWORD="${4:-Vall123@}"

echo "=========================================="
echo "API Authentication Test Script"
echo "=========================================="
echo "API URL: $API_URL"
echo "Endpoint: $ENDPOINT"
echo "Username: $USERNAME"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: No Authentication
echo "Test 1: No Authentication"
echo "-------------------------"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "${API_URL}${ENDPOINT}")
if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Success (200) - No authentication required${NC}"
elif [ "$RESPONSE" = "302" ]; then
    echo -e "${YELLOW}→ Redirect (302) - Authentication required${NC}"
elif [ "$RESPONSE" = "401" ]; then
    echo -e "${RED}✗ Unauthorized (401) - Authentication required${NC}"
else
    echo -e "${RED}✗ Error ($RESPONSE)${NC}"
fi
echo ""

# Test 2: Basic Authentication (Standard Authorization Header)
echo "Test 2: Basic Authentication (Authorization Header)"
echo "---------------------------------------------------"
BASIC_AUTH=$(echo -n "${USERNAME}:${PASSWORD}" | base64)
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Basic ${BASIC_AUTH}" \
    "${API_URL}${ENDPOINT}")
if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Success (200) - Standard Basic Auth working!${NC}"
elif [ "$RESPONSE" = "302" ]; then
    echo -e "${YELLOW}→ Redirect (302) - Standard Authorization header not accepted${NC}"
elif [ "$RESPONSE" = "401" ]; then
    echo -e "${RED}✗ Unauthorized (401) - Invalid credentials${NC}"
else
    echo -e "${RED}✗ Error ($RESPONSE)${NC}"
fi
echo ""

# Test 2b: Proxy-Authorization Header (Authelia Forward Auth)
echo "Test 2b: Basic Authentication (Proxy-Authorization Header)"
echo "----------------------------------------------------------"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Proxy-Authorization: Basic ${BASIC_AUTH}" \
    "${API_URL}${ENDPOINT}")
if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Success (200) - Proxy-Authorization working!${NC}"
    echo "   Authelia is configured as forward auth proxy"
elif [ "$RESPONSE" = "302" ]; then
    echo -e "${YELLOW}→ Redirect (302) - Proxy-Authorization not accepted${NC}"
elif [ "$RESPONSE" = "401" ]; then
    echo -e "${RED}✗ Unauthorized (401) - Invalid credentials${NC}"
else
    echo -e "${RED}✗ Error ($RESPONSE)${NC}"
fi
echo ""

# Test 3: Get Authelia Session Cookie
echo "Test 3: Session Authentication (Manual)"
echo "---------------------------------------"
echo "To test session authentication:"
echo "1. Open browser and go to: ${API_URL}${ENDPOINT}"
echo "2. Login with credentials: ${USERNAME} / ${PASSWORD}"
echo "3. Open Developer Tools → Application → Cookies"
echo "4. Copy the 'authelia_session' cookie value"
echo "5. Run this command with your cookie:"
echo ""
echo "curl '${API_URL}${ENDPOINT}' \\"
echo "  -H 'Cookie: authelia_session=YOUR_SESSION_COOKIE_HERE'"
echo ""

# Test 4: Check Authelia Configuration
echo "Test 4: Check Authelia Endpoints"
echo "---------------------------------"
AUTH_URL="https://auth.quickstark.com"
echo "Checking Authelia at: $AUTH_URL"

# Check if Authelia is responding
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "${AUTH_URL}/api/health")
if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Authelia is responding${NC}"
else
    echo -e "${RED}✗ Authelia health check failed ($RESPONSE)${NC}"
fi
echo ""

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="
echo "Based on the tests above:"
echo ""
if [ "$RESPONSE" = "302" ]; then
    echo "Your API requires authentication via Authelia."
    echo ""
    echo "Recommended Solutions:"
    echo "1. Enable Basic Auth in Authelia configuration"
    echo "2. Configure bypass rules for API endpoints"
    echo "3. Implement session-based authentication"
    echo ""
    echo "See AUTHELIA_SETUP.md for detailed configuration."
fi

echo ""
echo "For more details, check the logs:"
echo "- Authelia logs: docker logs authelia"
echo "- API logs: Check your API server logs"
echo ""
