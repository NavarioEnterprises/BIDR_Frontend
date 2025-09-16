#!/bin/bash

# Test script for api.bidr.co.za Auth Service
# Run this after SSL setup is complete

DOMAIN="api.bidr.co.za"
BASE_URL="https://$DOMAIN"

echo "🧪 Testing BIDR Auth Service Endpoints"
echo "Domain: $DOMAIN"
echo "Base URL: $BASE_URL"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

test_endpoint() {
    local endpoint=$1
    local method=${2:-GET}
    local data=$3
    
    echo -n "Testing $endpoint... "
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$endpoint")
    else
        response=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" -H "Content-Type: application/json" -d "$data" "$BASE_URL$endpoint")
    fi
    
    if [[ $response -ge 200 && $response -lt 400 ]]; then
        echo -e "${GREEN}✅ $response${NC}"
    else
        echo -e "${RED}❌ $response${NC}"
    fi
}

# Test basic endpoints
echo -e "${BLUE}📍 Basic Endpoints:${NC}"
test_endpoint "/"
test_endpoint "/health/"
test_endpoint "/admin/"

# Test auth endpoints
echo ""
echo -e "${BLUE}🔐 Auth Endpoints:${NC}"
test_endpoint "/register/" "POST" '{"email":"test@example.com","first_name":"Test","last_name":"User","phone_number":"1234567890","role":"buyer","password":"TestPass@123","confirm_password":"TestPass@123","delivery_method":"sms"}'
test_endpoint "/login/" "POST" '{"email":"test@example.com","password":"TestPass@123"}'

# Test SSL certificate
echo ""
echo -e "${BLUE}🔒 SSL Certificate:${NC}"
cert_info=$(openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -subject -dates 2>/dev/null)
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ SSL Certificate Valid${NC}"
    echo "$cert_info"
else
    echo -e "${RED}❌ SSL Certificate Issue${NC}"
fi

echo ""
echo "🎉 Testing complete!"
echo ""
echo "📱 Flutter Web should now work with:"
echo "   Base URL: $BASE_URL"
echo "   Registration: $BASE_URL/register/"
echo "   Login: $BASE_URL/login/"
echo ""
echo "🌐 Admin Panel: $BASE_URL/admin/"
echo "   Username: thulanik@bidr.co.za"
echo "   Password: Navario@544"
