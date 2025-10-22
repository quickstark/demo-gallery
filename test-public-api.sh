#!/bin/bash

# Test if API is publicly accessible (no auth required)

API_URL="https://api-images.quickstark.com"
ENDPOINT="/images?backend=mongo"

echo "=========================================="
echo "Testing Public API Access"
echo "=========================================="
echo ""
echo "API: ${API_URL}${ENDPOINT}"
echo ""

# Test without any authentication
echo "Testing without authentication..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "${API_URL}${ENDPOINT}")

if [ "$RESPONSE" = "200" ]; then
    echo "✅ SUCCESS! API is public (200 OK)"
    echo ""
    echo "Your API is now publicly accessible!"
    echo "The React app at http://localhost:3001 should work!"
elif [ "$RESPONSE" = "302" ]; then
    echo "❌ FAILED: Still getting redirect (302)"
    echo ""
    echo "Authelia is still requiring authentication."
    echo "Please update your Authelia configuration to bypass this domain."
elif [ "$RESPONSE" = "401" ]; then
    echo "❌ FAILED: Unauthorized (401)"
    echo ""
    echo "The API is still requiring authentication."
else
    echo "❌ FAILED: Error code $RESPONSE"
fi

echo ""
echo "Testing CORS preflight (OPTIONS)..."
PREFLIGHT=$(curl -s -o /dev/null -w "%{http_code}" -X OPTIONS "${API_URL}${ENDPOINT}")

if [ "$PREFLIGHT" = "200" ] || [ "$PREFLIGHT" = "204" ]; then
    echo "✅ CORS preflight working!"
else
    echo "⚠️  CORS preflight returned: $PREFLIGHT"
    echo "   This might cause issues in the browser."
fi

echo ""
echo "=========================================="
echo "Summary:"
echo "=========================================="

if [ "$RESPONSE" = "200" ]; then
    echo "✅ Your API is PUBLIC and working!"
    echo "✅ No authentication needed!"
    echo "✅ The React app should work now!"
else
    echo "❌ API still requires authentication"
    echo ""
    echo "To fix, add this to Authelia configuration.yml:"
    echo ""
    echo "access_control:"
    echo "  rules:"
    echo "    - domain: api-images.quickstark.com"
    echo "      policy: bypass"
    echo ""
    echo "Then restart Authelia."
fi


