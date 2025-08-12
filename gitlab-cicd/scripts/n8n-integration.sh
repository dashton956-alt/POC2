#!/bin/bash
# n8n integration script for CI/CD pipelines

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
        echo "Loading n8n environment from $env_file"
        set -a
        source "$env_file"
        set +a
    fi
}

# Load environment
load_env

# Default values with environment variable fallbacks
N8N_URL="${N8N_URL:-http://localhost:5678}"
N8N_API_KEY="${N8N_API_KEY:-}"
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

# Test n8n connectivity
test_n8n_connection() {
    log "$BLUE" "Testing n8n connection to $N8N_URL..."
    
    local response
    response=$(curl -s -w "%{http_code}" \
        -H "X-N8N-API-KEY: $N8N_API_KEY" \
        -H "Content-Type: application/json" \
        "$N8N_URL/api/v1/workflows" -o /dev/null || echo "000")
    
    if [ "$response" = "200" ]; then
        log "$GREEN" "n8n connection successful"
        return 0
    else
        log "$RED" "n8n connection failed (HTTP $response)"
        return 1
    fi
}

# Get n8n instance information
get_n8n_info() {
    log "$BLUE" "Getting n8n information..."
    
    local workflows
    workflows=$(curl -s -H "X-N8N-API-KEY: $N8N_API_KEY" \
        -H "Content-Type: application/json" \
        "$N8N_URL/api/v1/workflows")
    
    if [ $? -eq 0 ]; then
        echo "$workflows" | jq -r '
            "Total Workflows: " + (.data | length | tostring),
            "Active Workflows: " + ([.data[] | select(.active == true)] | length | tostring)
        '
        
        log "$BLUE" "Workflow List:"
        echo "$workflows" | jq -r '.data[] | "  - " + .name + " (ID: " + (.id | tostring) + ", Active: " + (.active | tostring) + ")"'
    else
        log "$RED" "Failed to get n8n information"
        return 1
    fi
}

# Deploy workflows from directory
deploy_workflows() {
    log "$BLUE" "Deploying workflows to n8n..."
    
    local workflows_dir="$PWD/n8n/workflows"
    if [ ! -d "$workflows_dir" ]; then
        log "$YELLOW" "Workflows directory not found, skipping deployment"
        return 0
    fi
    
    find "$workflows_dir" -name "*.json" | while read -r file; do
        log "$BLUE" "Processing workflow: $(basename "$file")"
        
        # Import workflow to n8n
        local import_response
        import_response=$(curl -s -X POST \
            -H "X-N8N-API-KEY: $N8N_API_KEY" \
            -H "Content-Type: application/json" \
            -d @"$file" \
            "$N8N_URL/api/v1/workflows/import")
        
        if echo "$import_response" | jq -e '.data.id' > /dev/null 2>&1; then
            local workflow_id
            workflow_id=$(echo "$import_response" | jq -r '.data.id')
            log "$GREEN" "Successfully imported workflow: $(basename "$file") (ID: $workflow_id)"
        else
            log "$RED" "Failed to import workflow: $(basename "$file")"
            echo "$import_response" | jq -r '.message // "Unknown error"'
        fi
    done
}

# Activate specified workflows
activate_workflows() {
    log "$BLUE" "Activating workflows..."
    
    local workflows_to_activate=("${@}")
    if [ ${#workflows_to_activate[@]} -eq 0 ]; then
        log "$YELLOW" "No workflows specified for activation"
        return 0
    fi
    
    for workflow_name in "${workflows_to_activate[@]}"; do
        log "$BLUE" "Activating workflow: $workflow_name"
        
        # Get workflow ID by name
        local workflow_id
        workflow_id=$(curl -s -H "X-N8N-API-KEY: $N8N_API_KEY" \
            "$N8N_URL/api/v1/workflows" | \
            jq -r --arg name "$workflow_name" '.data[] | select(.name == $name) | .id')
        
        if [ -z "$workflow_id" ] || [ "$workflow_id" = "null" ]; then
            log "$RED" "Workflow not found: $workflow_name"
            continue
        fi
        
        # Activate workflow
        local activate_response
        activate_response=$(curl -s -X PATCH \
            -H "X-N8N-API-KEY: $N8N_API_KEY" \
            -H "Content-Type: application/json" \
            -d '{"active": true}' \
            "$N8N_URL/api/v1/workflows/$workflow_id")
        
        if echo "$activate_response" | jq -e '.data.active' > /dev/null 2>&1; then
            log "$GREEN" "Successfully activated workflow: $workflow_name"
        else
            log "$RED" "Failed to activate workflow: $workflow_name"
        fi
    done
}

# Test workflow execution
test_workflow_execution() {
    local workflow_name="$1"
    
    if [ -z "$workflow_name" ]; then
        log "$RED" "Workflow name not provided for testing"
        return 1
    fi
    
    log "$BLUE" "Testing workflow execution: $workflow_name"
    
    # Get workflow ID
    local workflow_id
    workflow_id=$(curl -s -H "X-N8N-API-KEY: $N8N_API_KEY" \
        "$N8N_URL/api/v1/workflows" | \
        jq -r --arg name "$workflow_name" '.data[] | select(.name == $name) | .id')
    
    if [ -z "$workflow_id" ] || [ "$workflow_id" = "null" ]; then
        log "$RED" "Workflow not found: $workflow_name"
        return 1
    fi
    
    # Execute workflow manually
    local execution_response
    execution_response=$(curl -s -X POST \
        -H "X-N8N-API-KEY: $N8N_API_KEY" \
        -H "Content-Type: application/json" \
        "$N8N_URL/api/v1/workflows/$workflow_id/execute")
    
    if echo "$execution_response" | jq -e '.data.id' > /dev/null 2>&1; then
        local execution_id
        execution_id=$(echo "$execution_response" | jq -r '.data.id')
        log "$GREEN" "Workflow execution started: $execution_id"
        
        # Wait for execution to complete
        sleep 5
        
        # Check execution status
        local status_response
        status_response=$(curl -s -H "X-N8N-API-KEY: $N8N_API_KEY" \
            "$N8N_URL/api/v1/executions/$execution_id")
        
        local execution_status
        execution_status=$(echo "$status_response" | jq -r '.data.finished')
        
        if [ "$execution_status" = "true" ]; then
            log "$GREEN" "Workflow execution completed successfully"
        else
            log "$YELLOW" "Workflow execution may still be running or failed"
        fi
    else
        log "$RED" "Failed to execute workflow: $workflow_name"
        return 1
    fi
}

# Export workflows (backup)
backup_workflows() {
    log "$BLUE" "Backing up n8n workflows..."
    
    local backup_dir="$PWD/backups/workflows/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    local workflows
    workflows=$(curl -s -H "X-N8N-API-KEY: $N8N_API_KEY" \
        "$N8N_URL/api/v1/workflows")
    
    echo "$workflows" | jq -r '.data[] | @base64' | while read -r workflow; do
        local workflow_data
        workflow_data=$(echo "$workflow" | base64 -d)
        
        local workflow_name
        workflow_name=$(echo "$workflow_data" | jq -r '.name')
        
        local workflow_id
        workflow_id=$(echo "$workflow_data" | jq -r '.id')
        
        # Export individual workflow
        local export_response
        export_response=$(curl -s -H "X-N8N-API-KEY: $N8N_API_KEY" \
            "$N8N_URL/api/v1/workflows/$workflow_id/export")
        
        # Save to file
        local safe_name
        safe_name=$(echo "$workflow_name" | tr ' ' '_' | tr -cd '[:alnum:]_-')
        echo "$export_response" > "$backup_dir/${safe_name}_${workflow_id}.json"
        
        log "$GREEN" "Backed up workflow: $workflow_name"
    done
    
    log "$GREEN" "Workflow backup completed: $backup_dir"
}

# Validate workflows
validate_workflows() {
    log "$BLUE" "Validating n8n workflows..."
    
    local workflows_dir="$PWD/n8n/workflows"
    if [ ! -d "$workflows_dir" ]; then
        log "$YELLOW" "Workflows directory not found, skipping validation"
        return 0
    fi
    
    local validation_passed=true
    
    find "$workflows_dir" -name "*.json" | while read -r file; do
        log "$BLUE" "Validating workflow: $(basename "$file")"
        
        # Check if file is valid JSON
        if ! jq empty "$file" 2>/dev/null; then
            log "$RED" "Invalid JSON in workflow: $(basename "$file")"
            validation_passed=false
            continue
        fi
        
        # Check required fields
        local workflow_name
        workflow_name=$(jq -r '.name // empty' "$file")
        
        if [ -z "$workflow_name" ]; then
            log "$RED" "Workflow missing name field: $(basename "$file")"
            validation_passed=false
            continue
        fi
        
        # Check for nodes
        local node_count
        node_count=$(jq '.nodes | length' "$file")
        
        if [ "$node_count" -eq 0 ]; then
            log "$RED" "Workflow has no nodes: $(basename "$file")"
            validation_passed=false
            continue
        fi
        
        log "$GREEN" "Workflow validation passed: $(basename "$file") ($node_count nodes)"
    done
    
    if [ "$validation_passed" = true ]; then
        log "$GREEN" "All workflow validations passed"
        return 0
    else
        log "$RED" "Some workflow validations failed"
        return 1
    fi
}

# Main execution
main() {
    case "$OPERATION" in
        "test")
            test_n8n_connection
            get_n8n_info
            ;;
        "deploy")
            test_n8n_connection
            validate_workflows
            deploy_workflows
            ;;
        "activate")
            test_n8n_connection
            shift # Remove operation argument
            activate_workflows "$@"
            ;;
        "execute")
            test_n8n_connection
            test_workflow_execution "$2"
            ;;
        "backup")
            test_n8n_connection
            backup_workflows
            ;;
        "validate")
            validate_workflows
            ;;
        "info")
            test_n8n_connection
            get_n8n_info
            ;;
        *)
            echo "Usage: $0 {test|deploy|activate|execute|backup|validate|info}"
            echo "  test            - Test n8n connection and get info"
            echo "  deploy          - Validate and deploy workflows"
            echo "  activate [name] - Activate specific workflows"
            echo "  execute [name]  - Test execute a workflow"
            echo "  backup          - Backup all workflows"
            echo "  validate        - Validate workflow JSON files"
            echo "  info            - Get n8n instance information"
            exit 1
            ;;
    esac
}

main "$@"
