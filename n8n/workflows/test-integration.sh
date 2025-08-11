#!/bin/bash

# NetBox API Integration Test Script
# This script tests the NetBox API connection and basic functionality

set -e

# Configuration
NETBOX_URL="http://localhost:8000"
N8N_URL="http://localhost:5678"

echo "🔧 NetBox API Integration Test"
echo "=============================="
echo

# Test 1: Check if NetBox is accessible
echo "1. Testing NetBox connectivity..."
if curl -s -f "${NETBOX_URL}/login/" > /dev/null; then
    echo "✅ NetBox is accessible at ${NETBOX_URL}"
else
    echo "❌ NetBox is not accessible at ${NETBOX_URL}"
    echo "   Make sure NetBox is running with: cd /home/dan/POC2/netbox-docker && docker compose up -d"
    exit 1
fi

# Test 2: Check if n8n is accessible
echo
echo "2. Testing n8n connectivity..."
if curl -s -f "${N8N_URL}" > /dev/null; then
    echo "✅ n8n is accessible at ${N8N_URL}"
else
    echo "❌ n8n is not accessible at ${N8N_URL}"
    echo "   Make sure n8n is running with: cd /home/dan/POC2/n8n && docker compose up -d"
    exit 1
fi

# Test 3: Check NetBox API without authentication
echo
echo "3. Testing NetBox API endpoints..."
API_RESPONSE=$(curl -s "${NETBOX_URL}/api/")
if echo "$API_RESPONSE" | grep -q "dcim"; then
    echo "✅ NetBox API is responding correctly"
else
    echo "❌ NetBox API response is unexpected"
    echo "   Response: $API_RESPONSE"
fi

# Test 4: Check Docker containers
echo
echo "4. Checking Docker containers..."
echo
echo "NetBox containers:"
cd /home/dan/POC2/netbox-docker
docker compose ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo
echo "n8n containers:"
cd /home/dan/POC2/n8n
docker compose ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Test 5: Get NetBox API endpoints
echo
echo "5. Available NetBox API endpoints:"
curl -s "${NETBOX_URL}/api/" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for key in sorted(data.keys()):
        print(f'   • {key}: {data[key]}')
except:
    print('   ❌ Could not parse API endpoints')
"

# Test 6: Check if NetBox has any devices
echo
echo "6. Checking NetBox device count..."
DEVICE_COUNT=$(curl -s "${NETBOX_URL}/api/dcim/devices/" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('count', 0))
except:
    print('0')
")

echo "   📊 NetBox has ${DEVICE_COUNT} devices configured"

# Test 7: Instructions for API token
echo
echo "7. NetBox API Token Setup:"
echo "   📝 To use NetBox API with n8n, you need to create an API token:"
echo "   1. Go to ${NETBOX_URL}/admin/users/token/"
echo "   2. Click 'Add Token'"
echo "   3. Select a user and save"
echo "   4. Copy the token and add it to n8n credentials"

# Test 8: Test webhook endpoint (if n8n is running)
echo
echo "8. Testing n8n webhook capabilities..."
if curl -s "${N8N_URL}/webhook-test" > /dev/null 2>&1; then
    echo "✅ n8n webhook endpoint is accessible"
else
    echo "⚠️  n8n webhook test endpoint not found (this is normal)"
fi

echo
echo "🎉 Integration Test Complete!"
echo
echo "Next Steps:"
echo "1. Open NetBox at: ${NETBOX_URL}"
echo "2. Open n8n at: ${N8N_URL}"
echo "3. Create a NetBox API token and configure it in n8n"
echo "4. Import the provided workflows from /home/dan/POC2/n8n/workflows/"
echo
echo "📚 See the README.md for detailed integration instructions"
