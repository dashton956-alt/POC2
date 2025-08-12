#!/bin/bash
# NetBox integration script for CI/CD pipelines

set -e

# Load environment configuration
load_env() {
    local env_file=""
    
    # Determine which environment file to load
    if [ -f ".env.${CI_ENVIRONMENT_NAME}" ]; then
        env_file=".env.${CI_ENVIRONMENT_NAME}"
    elif [ -f ".env.local" ]; then
        env_file=".env.local"
    elif [ -f ".env" ]; then
        env_file=".env"
    fi
    
    # Load environment file if it exists
    if [ -n "$env_file" ] && [ -f "$env_file" ]; then
        echo "Loading NetBox environment from $env_file"
        set -a
        source "$env_file"
        set +a
    fi
}

# Load environment
load_env

# Default values with environment variable fallbacks
NETBOX_URL="${NETBOX_URL:-http://localhost:8000}"
NETBOX_TOKEN="${NETBOX_TOKEN:-}"
OPERATION="${1:-test}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    shift
    echo -e "${level}[$(date '+%Y-%m-%d %H:%M:%S')] $*${NC}"
}

# Test NetBox connectivity
test_netbox_connection() {
    log "$BLUE" "Testing NetBox connection to $NETBOX_URL..."
    
    if [ -z "$NETBOX_TOKEN" ]; then
        log "$RED" "ERROR: NETBOX_TOKEN is not set"
        return 1
    fi
    
    local response
    response=$(curl -s -w "%{http_code}" -H "Authorization: Token $NETBOX_TOKEN" \
        -H "Content-Type: application/json" \
        "$NETBOX_URL/api/status/" -o /dev/null || echo "000")
    
    if [ "$response" = "200" ]; then
        log "$GREEN" "NetBox connection successful"
        return 0
    else
        log "$RED" "NetBox connection failed (HTTP $response)"
        return 1
    fi
}

# Get NetBox version info
get_netbox_info() {
    log "$BLUE" "Getting NetBox information..."
    
    local info
    info=$(curl -s -H "Authorization: Token $NETBOX_TOKEN" \
        -H "Content-Type: application/json" \
        "$NETBOX_URL/api/status/")
    
    if [ $? -eq 0 ]; then
        echo "$info" | jq -r '
            "NetBox Version: " + .netbox_version,
            "Django Version: " + .django_version,
            "Python Version: " + .python_version,
            "Database: " + .database,
            "Redis: " + (.redis | if type == "object" then "Connected" else . end)
        '
    else
        log "$RED" "Failed to get NetBox information"
        return 1
    fi
}

# Deploy device types to NetBox
deploy_device_types() {
    log "$BLUE" "Deploying device types to NetBox..."
    
    local device_types_dir="$PWD/netbox-data/device-types"
    if [ ! -d "$device_types_dir" ]; then
        log "$YELLOW" "Device types directory not found, skipping deployment"
        return 0
    fi
    
    find "$device_types_dir" -name "*.yaml" -o -name "*.yml" | while read -r file; do
        log "$BLUE" "Processing device type: $(basename "$file")"
        
        # Convert YAML to JSON and POST to NetBox
        python3 -c "
import yaml
import json
import requests
import sys

with open('$file', 'r') as f:
    data = yaml.safe_load(f)

headers = {
    'Authorization': 'Token $NETBOX_TOKEN',
    'Content-Type': 'application/json'
}

# Create manufacturer first if needed
manufacturer_data = {
    'name': data['manufacturer'],
    'slug': data['manufacturer'].lower().replace(' ', '-')
}

response = requests.post('$NETBOX_URL/api/dcim/manufacturers/', 
                        headers=headers, json=manufacturer_data)

if response.status_code not in [200, 201, 400]:
    print(f'Failed to create manufacturer: {response.status_code}')
    sys.exit(1)

# Create device type
device_type_data = {
    'manufacturer': manufacturer_data['slug'],
    'model': data['model'],
    'slug': data['slug'],
    'part_number': data.get('part_number', ''),
    'u_height': data.get('u_height', 1),
    'is_full_depth': data.get('is_full_depth', True)
}

response = requests.post('$NETBOX_URL/api/dcim/device-types/', 
                        headers=headers, json=device_type_data)

if response.status_code in [200, 201]:
    print(f'Successfully deployed device type: {data[\"model\"]}')
else:
    print(f'Failed to deploy device type: {response.status_code} - {response.text}')
    sys.exit(1)
"
    done
}

# Validate NetBox data integrity
validate_netbox_data() {
    log "$BLUE" "Validating NetBox data integrity..."
    
    # Check for orphaned objects
    python3 -c "
import requests
import sys

headers = {
    'Authorization': 'Token $NETBOX_TOKEN',
    'Content-Type': 'application/json'
}

base_url = '$NETBOX_URL/api'

# Check devices without device types
devices_response = requests.get(f'{base_url}/dcim/devices/', headers=headers)
device_types_response = requests.get(f'{base_url}/dcim/device-types/', headers=headers)

if devices_response.status_code != 200 or device_types_response.status_code != 200:
    print('Failed to fetch data from NetBox')
    sys.exit(1)

devices = devices_response.json()['results']
device_types = {dt['id']: dt for dt in device_types_response.json()['results']}

orphaned_devices = []
for device in devices:
    if device['device_type']['id'] not in device_types:
        orphaned_devices.append(device['name'])

if orphaned_devices:
    print(f'Found {len(orphaned_devices)} orphaned devices: {orphaned_devices}')
    sys.exit(1)
else:
    print('NetBox data validation passed')
"
}

# Sync with n8n workflows
sync_with_n8n() {
    log "$BLUE" "Synchronizing NetBox data with n8n workflows..."
    
    if [ -z "$N8N_API_KEY" ]; then
        log "$YELLOW" "N8N_API_KEY not set, skipping n8n sync"
        return 0
    fi
    
    # Trigger n8n workflow to sync NetBox data
    local n8n_url="${N8N_URL:-http://localhost:5678}"
    local webhook_url="$n8n_url/webhook/netbox-sync"
    
    local sync_data="{
        \"event\": \"netbox_data_updated\",
        \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
        \"source\": \"gitlab_ci\",
        \"netbox_url\": \"$NETBOX_URL\"
    }"
    
    local response
    response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$sync_data" \
        "$webhook_url" -o /dev/null || echo "000")
    
    if [ "$response" = "200" ]; then
        log "$GREEN" "n8n synchronization triggered successfully"
    else
        log "$YELLOW" "n8n synchronization failed or webhook not available (HTTP $response)"
    fi
}

# Main execution
main() {
    case "$OPERATION" in
        "test")
            test_netbox_connection
            get_netbox_info
            ;;
        "deploy")
            test_netbox_connection
            deploy_device_types
            validate_netbox_data
            sync_with_n8n
            ;;
        "validate")
            test_netbox_connection
            validate_netbox_data
            ;;
        "sync")
            test_netbox_connection
            sync_with_n8n
            ;;
        "info")
            test_netbox_connection
            get_netbox_info
            ;;
        *)
            echo "Usage: $0 {test|deploy|validate|sync|info}"
            echo "  test     - Test NetBox connection and get info"
            echo "  deploy   - Deploy device types and validate"
            echo "  validate - Validate NetBox data integrity"
            echo "  sync     - Sync with n8n workflows"
            echo "  info     - Get NetBox information"
            exit 1
            ;;
    esac
}

main "$@"
