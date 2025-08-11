#!/bin/bash

# 🧪 Environment Variables Test Script
# Run this after importing environment-test.json workflow

echo "🧪 Testing n8n Environment Variables..."
echo "========================================"
echo ""

# Check if n8n is accessible
if ! curl -sf http://localhost:5678 > /dev/null 2>&1; then
    echo "❌ n8n is not accessible at http://localhost:5678"
    exit 1
fi

echo "✅ n8n is running"
echo ""

# Test NetBox API directly with environment variables
echo "🔍 Testing NetBox API with your configured token..."

NETBOX_TOKEN=$(grep "NETBOX_TOKEN=" n8n/docker-compose.yml | cut -d'=' -f2)
if [[ -n "$NETBOX_TOKEN" ]]; then
    echo "📝 Token found: ${NETBOX_TOKEN:0:10}..."
    
    if curl -sf -H "Authorization: Token $NETBOX_TOKEN" \
        http://localhost:8000/api/dcim/sites/ > /dev/null; then
        echo "✅ NetBox API authentication successful"
    else
        echo "❌ NetBox API authentication failed"
    fi
else
    echo "❌ NetBox token not found in docker-compose.yml"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Import environment-test.json in n8n"
echo "2. Import quick-start-ai-network.json in n8n"
echo "3. Both workflows will automatically use your environment variables!"
echo ""
echo "🌐 n8n Interface: http://localhost:5678"
echo "📊 NetBox Interface: http://localhost:8000"
