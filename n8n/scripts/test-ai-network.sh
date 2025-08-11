#!/bin/bash

# Quick test of AI Network Automation
echo "🧪 Testing AI Network Automation..."

# Get the webhook URL from n8n (you'll need to update this after importing)
WEBHOOK_URL="http://localhost:5678/webhook-test/ai-network-test"

echo "📡 Sending test request..."
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "user_request": "Create VLAN 100 for Marketing team in London office",
    "requester": "test@demo-corp.com"
  }' | jq '.'

echo ""
echo "✅ Test complete! Check the response above."
echo "🔗 If successful, you should see generated Ansible playbook content."
