#!/bin/bash

# 🔧 n8n Environment Variables Setup Script
# This script helps you configure n8n environment variables

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m' 
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if NetBox is running and get token
setup_netbox_token() {
    log "Setting up NetBox API token..."
    
    # Check if NetBox is accessible
    if ! curl -sf http://localhost:8000/api/ > /dev/null 2>&1; then
        error "NetBox is not accessible at http://localhost:8000"
        error "Please start NetBox first: cd ../netbox-docker && docker compose up -d"
        return 1
    fi
    
    echo ""
    echo "📋 To get your NetBox API token:"
    echo "1. Open: http://localhost:8000"
    echo "2. Login with your superuser account"
    echo "3. Go to: Admin → Users → [Your User] → API Tokens"
    echo "4. Click 'Add API Token'"
    echo "5. Set permissions to read/write"
    echo "6. Copy the generated token"
    echo ""
    
    read -p "Enter your NetBox API token: " -r netbox_token
    
    if [[ -z "$netbox_token" ]]; then
        error "NetBox token is required"
        return 1
    fi
    
    # Test the token
    log "Testing NetBox API token..."
    if curl -sf -H "Authorization: Token $netbox_token" \
        http://localhost:8000/api/dcim/sites/ > /dev/null; then
        success "NetBox API token is valid!"
        echo "$netbox_token"
    else
        error "NetBox API token is invalid"
        return 1
    fi
}

# Update docker-compose.yml with the token
update_compose_file() {
    local netbox_token="$1"
    
    log "Updating docker-compose.yml with NetBox token..."
    
    # Backup original file
    cp "$COMPOSE_FILE" "$COMPOSE_FILE.backup"
    
    # Replace the token in the file
    sed -i "s/NETBOX_TOKEN=change-me-to-your-netbox-token/NETBOX_TOKEN=$netbox_token/" "$COMPOSE_FILE"
    
    success "Updated docker-compose.yml with NetBox token"
}

# Setup OpenAI configuration
setup_openai() {
    echo ""
    log "Setting up OpenAI configuration..."
    echo ""
    echo "📋 OpenAI API Setup:"
    echo "1. Get API key from: https://platform.openai.com/api-keys"
    echo "2. Choose model: gpt-4 (recommended) or gpt-3.5-turbo (cheaper)"
    echo ""
    
    read -p "Enter your OpenAI API key (or press Enter to skip): " -r openai_key
    
    if [[ -n "$openai_key" ]]; then
        log "You'll need to create an OpenAI credential in n8n with this key"
        echo "OpenAI API Key: $openai_key"
        
        read -p "Enter OpenAI model (gpt-4 or gpt-3.5-turbo) [gpt-4]: " -r openai_model
        openai_model=${openai_model:-gpt-4}
        
        # Update compose file
        sed -i "s/OPENAI_MODEL=gpt-4/OPENAI_MODEL=$openai_model/" "$COMPOSE_FILE"
        success "Updated OpenAI model to $openai_model"
    else
        warn "Skipped OpenAI setup - you can add this later"
    fi
}

# Setup customer information
setup_customer() {
    echo ""
    log "Setting up customer configuration..."
    
    read -p "Enter customer ID [demo-corp]: " -r customer_id
    customer_id=${customer_id:-demo-corp}
    
    read -p "Enter customer name [Demo Corporation]: " -r customer_name
    customer_name=${customer_name:-Demo Corporation}
    
    # Update compose file
    sed -i "s/CUSTOMER_ID=demo-corp/CUSTOMER_ID=$customer_id/" "$COMPOSE_FILE"
    sed -i "s/CUSTOMER_NAME=Demo Corporation/CUSTOMER_NAME=$customer_name/" "$COMPOSE_FILE"
    
    success "Updated customer configuration: $customer_name ($customer_id)"
}

# Setup optional services
setup_optional() {
    echo ""
    log "Setting up optional services..."
    
    # GitLab
    read -p "Enter GitLab URL (or press Enter to skip) [https://gitlab.com]: " -r gitlab_url
    if [[ -n "$gitlab_url" ]]; then
        read -p "Enter GitLab project ID: " -r gitlab_project
        read -p "Enter GitLab token: " -r gitlab_token
        
        sed -i "s|GITLAB_URL=https://gitlab.com|GITLAB_URL=$gitlab_url|" "$COMPOSE_FILE"
        sed -i "s/GITLAB_PROJECT_ID=1/GITLAB_PROJECT_ID=$gitlab_project/" "$COMPOSE_FILE"
        sed -i "s/GITLAB_TOKEN=change-me-to-your-gitlab-token/GITLAB_TOKEN=$gitlab_token/" "$COMPOSE_FILE"
        
        success "Updated GitLab configuration"
    else
        warn "Skipped GitLab setup"
    fi
    
    # Email notifications
    read -p "Enter network team email (or press Enter to skip): " -r team_email
    if [[ -n "$team_email" ]]; then
        sed -i "s/NETWORK_TEAM_EMAIL=network@company.com/NETWORK_TEAM_EMAIL=$team_email/" "$COMPOSE_FILE"
        success "Updated team email: $team_email"
    fi
}

# Restart n8n with new configuration
restart_n8n() {
    echo ""
    log "Restarting n8n with new configuration..."
    
    if docker compose restart n8n-network-automation; then
        success "n8n restarted successfully!"
        echo ""
        echo "🌐 Access n8n at: http://localhost:5678"
        echo "📊 Username: admin"
        echo "🔒 Password: secure_password_change_me"
    else
        error "Failed to restart n8n"
        return 1
    fi
}

# Show next steps
show_next_steps() {
    echo ""
    echo "🎯 Next Steps:"
    echo "1. Access n8n: http://localhost:5678"
    echo "2. Create OpenAI credential in n8n (if using AI features)"
    echo "3. Import workflow template: quick-start-ai-network.json"
    echo "4. Test the workflow with:"
    echo "   ./test-ai-network.sh"
    echo ""
    echo "📁 Template files available:"
    echo "   - workflows/templates/quick-start-ai-network.json (Simple test)"
    echo "   - workflows/templates/ai-gitops-network-automation-template.json (Full pipeline)"
    echo ""
}

# Main execution
main() {
    echo "🔧 n8n Environment Variables Setup"
    echo "=================================="
    
    # Check prerequisites
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        error "docker-compose.yml not found in $SCRIPT_DIR"
        exit 1
    fi
    
    # Setup steps
    if netbox_token=$(setup_netbox_token); then
        update_compose_file "$netbox_token"
        setup_openai
        setup_customer
        setup_optional
        restart_n8n
        show_next_steps
        
        success "🎉 Environment setup complete!"
    else
        error "Setup failed - please check NetBox access"
        exit 1
    fi
}

main "$@"
