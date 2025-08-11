#!/bin/bash

# Multi-Tenant Customer Configuration Script
# This script helps manage customer configurations for multi-tenant n8n deployments

set -e

CONFIG_FILE="/home/dan/POC2/n8n/customer-configs.json"
CREDENTIALS_DIR="/home/dan/POC2/n8n/credentials"

echo "🏢 Multi-Tenant n8n Customer Management"
echo "======================================"
echo

# Initialize configuration file if it doesn't exist
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo '{"customers": {}}' > "$CONFIG_FILE"
    echo "✅ Initialized customer configuration file"
fi

# Create credentials directory
mkdir -p "$CREDENTIALS_DIR"

# Function to add a new customer
add_customer() {
    local customer_id="$1"
    local netbox_url="$2" 
    local api_token="$3"
    local webhook_prefix="$4"
    
    # Validate inputs
    if [[ -z "$customer_id" || -z "$netbox_url" || -z "$api_token" ]]; then
        echo "❌ Error: Missing required parameters"
        echo "Usage: add_customer <customer_id> <netbox_url> <api_token> [webhook_prefix]"
        return 1
    fi
    
    # Set default webhook prefix if not provided
    webhook_prefix="${webhook_prefix:-$customer_id}"
    
    echo "➕ Adding customer: $customer_id"
    
    # Create customer configuration
    cat > "/tmp/customer_config.json" << EOF
{
  "customer_id": "$customer_id",
  "netbox_url": "$netbox_url",
  "api_token_name": "netbox_${customer_id}",
  "webhook_prefix": "$webhook_prefix",
  "config_json": {
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "active": true,
    "features": {
      "device_discovery": true,
      "ipam_management": true, 
      "compliance_checking": true
    }
  }
}
EOF

    # Store API token securely
    cat > "$CREDENTIALS_DIR/netbox_${customer_id}.env" << EOF
NETBOX_TOKEN=$api_token
NETBOX_URL=$netbox_url
CUSTOMER_ID=$customer_id
WEBHOOK_PREFIX=$webhook_prefix
EOF
    
    # Update main configuration
    python3 << EOF
import json
import sys

try:
    # Load existing config
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    
    # Load new customer config
    with open('/tmp/customer_config.json', 'r') as f:
        new_customer = json.load(f)
    
    # Add to customers
    config['customers']['$customer_id'] = new_customer
    
    # Save updated config
    with open('$CONFIG_FILE', 'w') as f:
        json.dump(config, f, indent=2)
    
    print("✅ Customer $customer_id added successfully")
    
except Exception as e:
    print(f"❌ Error updating configuration: {e}")
    sys.exit(1)
EOF

    # Clean up temp file
    rm -f "/tmp/customer_config.json"
}

# Function to list customers
list_customers() {
    echo "📋 Current Customer Configurations:"
    echo "=================================="
    
    python3 << EOF
import json
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    
    if not config['customers']:
        print("   No customers configured yet.")
        exit()
    
    for customer_id, customer_config in config['customers'].items():
        print(f"   • Customer ID: {customer_id}")
        print(f"     NetBox URL: {customer_config['netbox_url']}")  
        print(f"     Webhook Prefix: {customer_config['webhook_prefix']}")
        print(f"     API Token: netbox_{customer_id}")
        print(f"     Active: {customer_config['config_json']['active']}")
        print()
        
except Exception as e:
    print(f"❌ Error reading configuration: {e}")
EOF
}

# Function to generate webhook URLs
generate_webhook_urls() {
    local base_url="${1:-http://localhost:5678}"
    
    echo "🔗 Multi-Tenant Webhook URLs:"
    echo "============================"
    
    python3 << EOF
import json
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    
    if not config['customers']:
        print("   No customers configured yet.")
        exit()
    
    print(f"   Base n8n URL: $base_url")
    print()
    
    for customer_id, customer_config in config['customers'].items():
        prefix = customer_config['webhook_prefix']
        print(f"   Customer: {customer_id}")
        print(f"   • Device Discovery: $base_url/webhook/{prefix}-devices")
        print(f"   • IPAM Management: $base_url/webhook/{prefix}-ipam") 
        print(f"   • Compliance Check: $base_url/webhook/{prefix}-compliance")
        print(f"   • Multi-Tenant API: $base_url/webhook/mt-netbox-api")
        print("     Headers: {'x-customer-id': '" + customer_id + "'}")
        print()
        
except Exception as e:
    print(f"❌ Error generating URLs: {e}")
EOF
}

# Function to test customer API
test_customer_api() {
    local customer_id="$1"
    local n8n_url="${2:-http://localhost:5678}"
    
    if [[ -z "$customer_id" ]]; then
        echo "❌ Error: Customer ID required"
        echo "Usage: test_customer_api <customer_id> [n8n_url]"
        return 1
    fi
    
    echo "🧪 Testing API for customer: $customer_id"
    echo "========================================"
    
    # Test device discovery
    echo "Testing device discovery..."
    curl -X POST "$n8n_url/webhook/mt-netbox-api" \
      -H "Content-Type: application/json" \
      -H "x-customer-id: $customer_id" \
      -d '{
        "action": "get_devices",
        "data": {}
      }' \
      -w "\nHTTP Status: %{http_code}\n" \
      -s | head -20
      
    echo
    echo "✅ Test completed for customer: $customer_id"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <command> [options]"
    echo
    echo "Commands:"
    echo "  add <customer_id> <netbox_url> <api_token> [webhook_prefix]"
    echo "                    Add a new customer configuration"
    echo "  list              List all configured customers"
    echo "  urls [base_url]   Generate webhook URLs for all customers" 
    echo "  test <customer_id> [n8n_url]  Test API for specific customer"
    echo
    echo "Examples:"
    echo "  $0 add acme-corp http://acme-netbox:8000 abc123token"
    echo "  $0 add customer-b http://customerb.netbox.com:8000 def456token cb"
    echo "  $0 list"
    echo "  $0 urls http://n8n.company.com:5678" 
    echo "  $0 test acme-corp"
}

# Main script logic
case "${1:-}" in
    "add")
        add_customer "$2" "$3" "$4" "$5"
        ;;
    "list")
        list_customers
        ;;
    "urls")
        generate_webhook_urls "$2"
        ;;
    "test")
        test_customer_api "$2" "$3"
        ;;
    "help"|"--help"|"-h")
        show_usage
        ;;
    *)
        echo "❌ Error: Invalid command"
        echo
        show_usage
        exit 1
        ;;
esac
