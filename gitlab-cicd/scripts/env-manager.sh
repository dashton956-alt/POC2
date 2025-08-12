#!/bin/bash
# Environment management script for GitLab CI/CD Pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${1}[$(date '+%H:%M:%S')] $2${NC}"
}

# Function to display help
show_help() {
    echo "Environment Management Script for GitLab CI/CD Pipeline"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  init [ENV]         Initialize environment configuration"
    echo "  validate [ENV]     Validate environment configuration"
    echo "  show [ENV]         Show environment variables (masked)"
    echo "  copy ENV1 ENV2     Copy configuration from ENV1 to ENV2"
    echo "  generate-tokens    Generate secure API tokens"
    echo "  test [ENV]         Test API connectivity with environment"
    echo ""
    echo "Environments:"
    echo "  local              Local development environment"
    echo "  development        Development environment"
    echo "  staging            Staging environment"
    echo "  production         Production environment"
    echo ""
    echo "Examples:"
    echo "  $0 init local                    # Initialize local environment"
    echo "  $0 validate production           # Validate production config"
    echo "  $0 test development              # Test development API connectivity"
    echo "  $0 copy development staging      # Copy dev config to staging"
    echo "  $0 generate-tokens               # Generate secure tokens"
}

# Function to check if environment file exists
check_env_file() {
    local env="$1"
    local env_file
    
    # Check if we're in the scripts directory, adjust paths accordingly
    if [[ $(basename "$PWD") == "scripts" ]]; then
        env_file="../.env.$env"
    else
        env_file=".env.$env"
    fi
    
    if [ ! -f "$env_file" ]; then
        log "$RED" "Environment file $env_file does not exist"
        return 1
    fi
    return 0
}

# Function to generate secure tokens
generate_tokens() {
    log "$BLUE" "Generating secure API tokens..."
    
    # Generate random tokens
    local netbox_token=$(openssl rand -hex 32)
    local n8n_api_key=$(openssl rand -hex 32)
    local secret_key=$(openssl rand -hex 64)
    local gitlab_token=$(openssl rand -hex 32)
    
    echo ""
    log "$GREEN" "Generated tokens (save these securely):"
    echo "NETBOX_TOKEN=$netbox_token"
    echo "N8N_API_KEY=$n8n_api_key"
    echo "SECRET_KEY=$secret_key"
    echo "GITLAB_TOKEN=$gitlab_token"
    echo ""
    log "$YELLOW" "Remember to update your environment files with these tokens!"
}

# Function to initialize environment
init_env() {
    local env="${1:-local}"
    local env_file="../.env.$env"
    local example_file="../.env.example"
    
    # Check if we're in the scripts directory, adjust paths accordingly
    if [[ $(basename "$PWD") == "scripts" ]]; then
        env_file="../.env.$env"
        example_file="../.env.example"
    else
        env_file=".env.$env"
        example_file=".env.example"
    fi
    
    if [ -f "$env_file" ]; then
        log "$YELLOW" "Environment file $env_file already exists"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "$BLUE" "Skipping initialization"
            return 0
        fi
    fi
    
    if [ ! -f "$example_file" ]; then
        log "$RED" "Example file $example_file not found"
        return 1
    fi
    
    # Copy example file
    cp "$example_file" "$env_file"
    
    # Update environment-specific values
    case "$env" in
        "local")
            sed -i 's/ENVIRONMENT=development/ENVIRONMENT=local/' "$env_file"
            sed -i 's/http:\/\/localhost:8000/http:\/\/localhost:8000/' "$env_file"
            sed -i 's/DEBUG=false/DEBUG=true/' "$env_file"
            ;;
        "development")
            sed -i 's/ENVIRONMENT=development/ENVIRONMENT=development/' "$env_file"
            sed -i 's/http:\/\/localhost:8000/http:\/\/netbox-dev:8000/' "$env_file"
            sed -i 's/http:\/\/localhost:5678/http:\/\/n8n-dev:5678/' "$env_file"
            ;;
        "staging")
            sed -i 's/ENVIRONMENT=development/ENVIRONMENT=staging/' "$env_file"
            sed -i 's/http:\/\/localhost:8000/http:\/\/netbox-staging:8000/' "$env_file"
            sed -i 's/http:\/\/localhost:5678/http:\/\/n8n-staging:5678/' "$env_file"
            ;;
        "production")
            sed -i 's/ENVIRONMENT=development/ENVIRONMENT=production/' "$env_file"
            sed -i 's/http:\/\/localhost:8000/http:\/\/netbox-prod:8000/' "$env_file"
            sed -i 's/http:\/\/localhost:5678/http:\/\/n8n-prod:5678/' "$env_file"
            sed -i 's/DEBUG=false/DEBUG=false/' "$env_file"
            sed -i 's/LOG_LEVEL=INFO/LOG_LEVEL=WARNING/' "$env_file"
            ;;
    esac
    
    log "$GREEN" "Environment file $env_file initialized"
    log "$YELLOW" "Please edit $env_file to set your actual API tokens and configuration"
}

# Function to validate environment
validate_env() {
    local env="${1:-local}"
    local env_file
    
    # Check if we're in the scripts directory, adjust paths accordingly
    if [[ $(basename "$PWD") == "scripts" ]]; then
        env_file="../.env.$env"
    else
        env_file=".env.$env"
    fi
    
    if ! check_env_file "$env"; then
        return 1
    fi
    
    log "$BLUE" "Validating environment: $env"
    
    # Load environment variables
    set -a
    source "$env_file"
    set +a
    
    local validation_errors=0
    
    # Check required variables
    local required_vars=("NETBOX_URL" "NETBOX_TOKEN" "N8N_URL" "N8N_API_KEY" "ENVIRONMENT")
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log "$RED" "Missing required variable: $var"
            validation_errors=$((validation_errors + 1))
        elif [[ "${!var}" == *"replace_me"* ]] || [[ "${!var}" == *"your-"* ]]; then
            log "$YELLOW" "Variable $var appears to contain placeholder value: ${!var}"
            validation_errors=$((validation_errors + 1))
        else
            log "$GREEN" "✓ $var is set"
        fi
    done
    
    # Validate URLs
    if [[ -n "$NETBOX_URL" && ! "$NETBOX_URL" =~ ^https?:// ]]; then
        log "$RED" "NETBOX_URL should start with http:// or https://"
        validation_errors=$((validation_errors + 1))
    fi
    
    if [[ -n "$N8N_URL" && ! "$N8N_URL" =~ ^https?:// ]]; then
        log "$RED" "N8N_URL should start with http:// or https://"
        validation_errors=$((validation_errors + 1))
    fi
    
    if [ $validation_errors -eq 0 ]; then
        log "$GREEN" "Environment validation passed"
        return 0
    else
        log "$RED" "Environment validation failed with $validation_errors errors"
        return 1
    fi
}

# Function to show environment (with masked sensitive values)
show_env() {
    local env="${1:-local}"
    local env_file
    
    # Check if we're in the scripts directory, adjust paths accordingly
    if [[ $(basename "$PWD") == "scripts" ]]; then
        env_file="../.env.$env"
    else
        env_file=".env.$env"
    fi
    
    if ! check_env_file "$env"; then
        return 1
    fi
    
    log "$BLUE" "Environment variables for: $env"
    echo ""
    
    # Read and display environment file with masked sensitive values
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ $line =~ ^#.*$ ]] || [[ -z $line ]]; then
            echo "$line"
            continue
        fi
        
        # Extract variable name and value
        if [[ $line =~ ^([^=]+)=(.*)$ ]]; then
            local var_name="${BASH_REMATCH[1]}"
            local var_value="${BASH_REMATCH[2]}"
            
            # Mask sensitive values
            if [[ $var_name =~ (TOKEN|KEY|PASSWORD|SECRET) ]]; then
                if [ ${#var_value} -gt 8 ]; then
                    local masked_value="${var_value:0:4}****${var_value: -4}"
                    echo "$var_name=$masked_value"
                else
                    echo "$var_name=****"
                fi
            else
                echo "$line"
            fi
        else
            echo "$line"
        fi
    done < "$env_file"
}

# Function to copy environment
copy_env() {
    local source_env="$1"
    local target_env="$2"
    
    if [ -z "$source_env" ] || [ -z "$target_env" ]; then
        log "$RED" "Both source and target environments are required"
        return 1
    fi
    
    local source_file target_file
    
    # Check if we're in the scripts directory, adjust paths accordingly
    if [[ $(basename "$PWD") == "scripts" ]]; then
        source_file="../.env.$source_env"
        target_file="../.env.$target_env"
    else
        source_file=".env.$source_env"
        target_file=".env.$target_env"
    fi
    
    if ! check_env_file "$source_env"; then
        return 1
    fi
    
    if [ -f "$target_file" ]; then
        log "$YELLOW" "Target environment file $target_file already exists"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "$BLUE" "Skipping copy operation"
            return 0
        fi
    fi
    
    cp "$source_file" "$target_file"
    
    # Update environment name in the target file
    sed -i "s/ENVIRONMENT=$source_env/ENVIRONMENT=$target_env/" "$target_file"
    
    log "$GREEN" "Copied environment from $source_env to $target_env"
    log "$YELLOW" "Please review and update $target_file as needed"
}

# Function to test environment connectivity
test_env() {
    local env="${1:-local}"
    local env_file
    
    # Check if we're in the scripts directory, adjust paths accordingly
    if [[ $(basename "$PWD") == "scripts" ]]; then
        env_file="../.env.$env"
    else
        env_file=".env.$env"
    fi
    
    if ! check_env_file "$env"; then
        return 1
    fi
    
    # Validate first
    if ! validate_env "$env"; then
        log "$RED" "Environment validation failed, skipping connectivity tests"
        return 1
    fi
    
    log "$BLUE" "Testing connectivity for environment: $env"
    
    # Load environment
    set -a
    source "$env_file"
    set +a
    
    # Test NetBox connectivity
    log "$BLUE" "Testing NetBox connectivity..."
    if curl -s -f -H "Authorization: Token $NETBOX_TOKEN" "$NETBOX_URL/api/status/" > /dev/null; then
        log "$GREEN" "✓ NetBox API is accessible"
    else
        log "$RED" "✗ NetBox API is not accessible"
    fi
    
    # Test n8n connectivity
    log "$BLUE" "Testing n8n connectivity..."
    if [ -n "$N8N_API_KEY" ]; then
        if curl -s -f -H "X-N8N-API-KEY: $N8N_API_KEY" "$N8N_URL/api/v1/workflows" > /dev/null; then
            log "$GREEN" "✓ n8n API is accessible"
        else
            log "$RED" "✗ n8n API is not accessible"
        fi
    else
        if curl -s -f "$N8N_URL/api/v1/workflows" > /dev/null; then
            log "$GREEN" "✓ n8n API is accessible (no auth)"
        else
            log "$RED" "✗ n8n API is not accessible"
        fi
    fi
}

# Main function
main() {
    local command="${1:-help}"
    
    case "$command" in
        "init")
            init_env "$2"
            ;;
        "validate")
            validate_env "$2"
            ;;
        "show")
            show_env "$2"
            ;;
        "copy")
            copy_env "$2" "$3"
            ;;
        "generate-tokens")
            generate_tokens
            ;;
        "test")
            test_env "$2"
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            log "$RED" "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
