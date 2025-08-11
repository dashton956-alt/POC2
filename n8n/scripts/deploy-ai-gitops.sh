#!/bin/bash

# 🤖 AI GitOps Template Deployment Script
# Deploys the AI-powered network automation workflow for customers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${SCRIPT_DIR}/workflows/templates"
CONFIG_DIR="${SCRIPT_DIR}/customer-configs"
CREDENTIALS_DIR="${SCRIPT_DIR}/credentials"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Usage function
usage() {
    cat << EOF
🤖 AI GitOps Template Deployment

Usage: $0 [COMMAND] [OPTIONS]

Commands:
  deploy-customer <customer_id> <customer_name> <netbox_url> <git_project_id>
    Deploy AI GitOps workflow for a new customer

  update-customer <customer_id>
    Update existing customer deployment with latest template

  list-customers
    List all deployed customers

  test-customer <customer_id>
    Test customer deployment with sample request

  remove-customer <customer_id>
    Remove customer deployment (use with caution)

Examples:
  $0 deploy-customer "acme-corp" "ACME Corporation" "https://netbox.acme.com" "12345"
  $0 test-customer "acme-corp"
  $0 list-customers

Environment Variables:
  N8N_API_URL       - n8n API endpoint (default: http://localhost:5678)
  N8N_API_KEY       - n8n API authentication key
  OPENAI_API_KEY    - OpenAI API key for AI features
  DEFAULT_GITLAB_URL - Default GitLab URL for customers

EOF
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check required files
    if [[ ! -f "${TEMPLATE_DIR}/ai-gitops-network-automation-template.json" ]]; then
        error "AI GitOps template file not found!"
        exit 1
    fi
    
    # Check n8n connectivity
    if ! curl -sf "${N8N_API_URL:-http://localhost:5678}/healthz" > /dev/null 2>&1; then
        error "n8n instance not accessible at ${N8N_API_URL:-http://localhost:5678}"
        exit 1
    fi
    
    # Create directories if they don't exist
    mkdir -p "${CONFIG_DIR}" "${CREDENTIALS_DIR}"
    
    success "Prerequisites check passed"
}

# Deploy workflow for customer
deploy_customer() {
    local customer_id="$1"
    local customer_name="$2"
    local netbox_url="$3"
    local git_project_id="$4"
    
    log "Deploying AI GitOps workflow for customer: ${customer_name} (${customer_id})"
    
    # Create customer configuration
    local config_file="${CONFIG_DIR}/${customer_id}.json"
    cat > "${config_file}" << EOF
{
  "customer_id": "${customer_id}",
  "customer_name": "${customer_name}",
  "netbox_url": "${netbox_url}",
  "git_project_id": "${git_project_id}",
  "gitlab_url": "${DEFAULT_GITLAB_URL:-https://gitlab.com}",
  "deployed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "template_version": "2.0",
  "workflow_id": null,
  "webhook_url": null,
  "status": "deploying"
}
EOF
    
    # Create environment file
    local env_file="${CREDENTIALS_DIR}/${customer_id}.env"
    cat > "${env_file}" << EOF
# Customer: ${customer_name}
CUSTOMER_ID=${customer_id}
CUSTOMER_NAME="${customer_name}"
NETBOX_URL=${netbox_url}
GITLAB_PROJECT_ID=${git_project_id}
GITLAB_URL=${DEFAULT_GITLAB_URL:-https://gitlab.com}
OPENAI_MODEL=gpt-4
WEBHOOK_PREFIX=${customer_id}

# Add your customer-specific credentials:
# NETBOX_TOKEN=
# GITLAB_TOKEN=
# SERVICENOW_URL=
# SERVICENOW_USER=
# SERVICENOW_PASSWORD=
# NETWORK_TEAM_EMAIL=
# SLACK_CREDENTIAL_ID=
# EMAIL_CREDENTIAL_ID=
# OPENAI_CREDENTIAL_ID=
EOF
    
    # Load template and customize for customer
    log "Customizing template for ${customer_id}..."
    local template_content
    template_content=$(cat "${TEMPLATE_DIR}/ai-gitops-network-automation-template.json")
    
    # Replace template placeholders
    template_content=$(echo "$template_content" | sed "s/{{ \$env\.CUSTOMER_ID }}/${customer_id}/g")
    template_content=$(echo "$template_content" | sed "s/\"{{ \$env\.CUSTOMER_ID }}-ai-gitops\"/\"${customer_id}-ai-gitops\"/g")
    
    # Update workflow name
    template_content=$(echo "$template_content" | jq --arg name "AI GitOps - ${customer_name}" '.name = $name')
    
    # Create temporary file for deployment
    local temp_file=$(mktemp)
    echo "$template_content" > "$temp_file"
    
    # Deploy to n8n
    log "Deploying workflow to n8n..."
    local response
    if ! response=$(curl -sf -X POST \
        "${N8N_API_URL:-http://localhost:5678}/api/v1/workflows" \
        -H "Content-Type: application/json" \
        -H "X-N8N-API-KEY: ${N8N_API_KEY:-}" \
        -d @"$temp_file" 2>/dev/null); then
        error "Failed to deploy workflow to n8n"
        rm -f "$temp_file"
        exit 1
    fi
    
    # Extract workflow ID and webhook URL
    local workflow_id
    local webhook_url
    workflow_id=$(echo "$response" | jq -r '.id // empty')
    webhook_url="${N8N_API_URL:-http://localhost:5678}/webhook/${customer_id}-ai-gitops"
    
    # Update configuration with deployment info
    jq --arg workflow_id "$workflow_id" \
       --arg webhook_url "$webhook_url" \
       --arg status "deployed" \
       '.workflow_id = $workflow_id | .webhook_url = $webhook_url | .status = $status' \
       "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
    
    # Clean up
    rm -f "$temp_file"
    
    success "Successfully deployed AI GitOps workflow for ${customer_name}"
    echo ""
    echo "📝 Deployment Details:"
    echo "   Customer ID: ${customer_id}"
    echo "   Workflow ID: ${workflow_id}"
    echo "   Webhook URL: ${webhook_url}"
    echo "   Config File: ${config_file}"
    echo "   Environment: ${env_file}"
    echo ""
    warn "⚠️  Don't forget to:"
    echo "   1. Edit ${env_file} with customer credentials"
    echo "   2. Configure n8n credentials for OpenAI, GitLab, etc."
    echo "   3. Test the deployment with: $0 test-customer ${customer_id}"
}

# Update existing customer deployment
update_customer() {
    local customer_id="$1"
    local config_file="${CONFIG_DIR}/${customer_id}.json"
    
    if [[ ! -f "$config_file" ]]; then
        error "Customer ${customer_id} not found. Use deploy-customer first."
        exit 1
    fi
    
    log "Updating AI GitOps workflow for customer: ${customer_id}"
    
    # Get existing workflow ID
    local workflow_id
    workflow_id=$(jq -r '.workflow_id // empty' "$config_file")
    
    if [[ -z "$workflow_id" ]]; then
        error "No workflow ID found for customer ${customer_id}"
        exit 1
    fi
    
    # Load and customize template
    local template_content
    template_content=$(cat "${TEMPLATE_DIR}/ai-gitops-network-automation-template.json")
    
    # Get customer details
    local customer_name
    customer_name=$(jq -r '.customer_name' "$config_file")
    
    # Customize template
    template_content=$(echo "$template_content" | sed "s/{{ \$env\.CUSTOMER_ID }}/${customer_id}/g")
    template_content=$(echo "$template_content" | jq --arg name "AI GitOps - ${customer_name}" '.name = $name')
    
    # Create temporary file
    local temp_file=$(mktemp)
    echo "$template_content" > "$temp_file"
    
    # Update workflow in n8n
    if ! curl -sf -X PUT \
        "${N8N_API_URL:-http://localhost:5678}/api/v1/workflows/${workflow_id}" \
        -H "Content-Type: application/json" \
        -H "X-N8N-API-KEY: ${N8N_API_KEY:-}" \
        -d @"$temp_file" > /dev/null; then
        error "Failed to update workflow in n8n"
        rm -f "$temp_file"
        exit 1
    fi
    
    # Update configuration
    jq --arg updated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       '.updated_at = $updated_at | .template_version = "2.0"' \
       "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
    
    # Clean up
    rm -f "$temp_file"
    
    success "Successfully updated AI GitOps workflow for ${customer_id}"
}

# List all deployed customers
list_customers() {
    log "Listing deployed customers..."
    echo ""
    
    if [[ ! -d "$CONFIG_DIR" ]] || [[ -z "$(ls -A "$CONFIG_DIR" 2>/dev/null)" ]]; then
        warn "No customers deployed yet"
        return
    fi
    
    printf "%-15s %-30s %-20s %-10s\n" "Customer ID" "Customer Name" "Deployed At" "Status"
    printf "%-15s %-30s %-20s %-10s\n" "----------" "------------" "----------" "------"
    
    for config_file in "$CONFIG_DIR"/*.json; do
        if [[ -f "$config_file" ]]; then
            local customer_id customer_name deployed_at status
            customer_id=$(jq -r '.customer_id' "$config_file")
            customer_name=$(jq -r '.customer_name' "$config_file")
            deployed_at=$(jq -r '.deployed_at' "$config_file")
            status=$(jq -r '.status' "$config_file")
            
            printf "%-15s %-30s %-20s %-10s\n" "$customer_id" "$customer_name" \
                   "$(date -d "$deployed_at" +'%Y-%m-%d %H:%M' 2>/dev/null || echo "$deployed_at")" \
                   "$status"
        fi
    done
    echo ""
}

# Test customer deployment
test_customer() {
    local customer_id="$1"
    local config_file="${CONFIG_DIR}/${customer_id}.json"
    
    if [[ ! -f "$config_file" ]]; then
        error "Customer ${customer_id} not found"
        exit 1
    fi
    
    log "Testing AI GitOps deployment for customer: ${customer_id}"
    
    local webhook_url
    webhook_url=$(jq -r '.webhook_url' "$config_file")
    
    if [[ -z "$webhook_url" || "$webhook_url" == "null" ]]; then
        error "No webhook URL found for customer ${customer_id}"
        exit 1
    fi
    
    # Test request payload
    local test_payload
    test_payload=$(cat << EOF
{
  "user_request": "Test VLAN creation for customer ${customer_id} - this is a validation test",
  "requester": "automation-test@n8n.local",
  "urgency": "low",
  "test_mode": true
}
EOF
)
    
    log "Sending test request to: ${webhook_url}"
    
    # Make test request
    local response
    if response=$(curl -sf -X POST "$webhook_url" \
        -H "Content-Type: application/json" \
        -H "X-Customer-ID: ${customer_id}" \
        -d "$test_payload" 2>/dev/null); then
        success "Test request successful!"
        echo ""
        echo "📊 Response:"
        echo "$response" | jq '.'
    else
        error "Test request failed"
        exit 1
    fi
}

# Remove customer deployment
remove_customer() {
    local customer_id="$1"
    local config_file="${CONFIG_DIR}/${customer_id}.json"
    
    if [[ ! -f "$config_file" ]]; then
        error "Customer ${customer_id} not found"
        exit 1
    fi
    
    warn "⚠️  This will permanently remove the AI GitOps deployment for customer: ${customer_id}"
    read -p "Are you sure? (yes/no): " -r
    
    if [[ ! $REPLY =~ ^yes$ ]]; then
        log "Aborted"
        exit 0
    fi
    
    log "Removing AI GitOps deployment for customer: ${customer_id}"
    
    # Get workflow ID
    local workflow_id
    workflow_id=$(jq -r '.workflow_id // empty' "$config_file")
    
    # Delete from n8n if workflow ID exists
    if [[ -n "$workflow_id" ]]; then
        if curl -sf -X DELETE \
            "${N8N_API_URL:-http://localhost:5678}/api/v1/workflows/${workflow_id}" \
            -H "X-N8N-API-KEY: ${N8N_API_KEY:-}" > /dev/null; then
            success "Removed workflow from n8n"
        else
            warn "Failed to remove workflow from n8n (may have been deleted already)"
        fi
    fi
    
    # Remove configuration files
    rm -f "$config_file"
    rm -f "${CREDENTIALS_DIR}/${customer_id}.env"
    
    success "Successfully removed AI GitOps deployment for customer: ${customer_id}"
}

# Main script logic
main() {
    if [[ $# -lt 1 ]]; then
        usage
        exit 1
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        "deploy-customer")
            if [[ $# -ne 4 ]]; then
                error "deploy-customer requires 4 arguments: <customer_id> <customer_name> <netbox_url> <git_project_id>"
                exit 1
            fi
            check_prerequisites
            deploy_customer "$@"
            ;;
        "update-customer")
            if [[ $# -ne 1 ]]; then
                error "update-customer requires 1 argument: <customer_id>"
                exit 1
            fi
            check_prerequisites
            update_customer "$@"
            ;;
        "list-customers")
            list_customers
            ;;
        "test-customer")
            if [[ $# -ne 1 ]]; then
                error "test-customer requires 1 argument: <customer_id>"
                exit 1
            fi
            test_customer "$@"
            ;;
        "remove-customer")
            if [[ $# -ne 1 ]]; then
                error "remove-customer requires 1 argument: <customer_id>"
                exit 1
            fi
            remove_customer "$@"
            ;;
        *)
            error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
