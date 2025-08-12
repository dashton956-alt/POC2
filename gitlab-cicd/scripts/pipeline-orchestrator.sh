#!/bin/bash
# Master CI/CD pipeline orchestrator script

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
        echo "Loading environment from $env_file"
        # Export variables from env file (ignore comments and empty lines)
        set -a
        source "$env_file"
        set +a
    else
        echo "Warning: No environment file found. Using default/CI variables."
    fi
}

# Load environment configuration
load_env

# Default values (with fallbacks)
ENVIRONMENT="${CI_ENVIRONMENT_NAME:-${ENVIRONMENT:-development}}"
PIPELINE_STAGE="${CI_JOB_STAGE:-test}"
PROJECT_NAME="${CI_PROJECT_NAME:-${PROJECT_NAME:-poc2-automation}}"

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
    echo -e "${level}[$(date '+%Y-%m-%d %H:%M:%S')] [$PIPELINE_STAGE] $*${NC}"
}

# Initialize pipeline environment
init_pipeline() {
    log "$BLUE" "Initializing CI/CD pipeline for $PROJECT_NAME ($ENVIRONMENT)"
    
    # Create necessary directories
    mkdir -p logs reports artifacts backups
    
    # Set up logging
    exec > >(tee -a "logs/pipeline_$(date +%Y%m%d_%H%M%S).log") 2>&1
    
    # Environment validation
    log "$BLUE" "Validating environment variables..."
    
    local required_vars=("NETBOX_URL" "NETBOX_TOKEN" "N8N_URL")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log "$RED" "Missing required environment variables: ${missing_vars[*]}"
        return 1
    fi
    
    log "$GREEN" "Pipeline initialization completed"
}

# Health check stage
health_check() {
    log "$BLUE" "Running health checks..."
    
    local health_status=0
    
    # NetBox health check
    log "$BLUE" "Checking NetBox connectivity..."
    if /app/scripts/netbox-integration.sh test; then
        log "$GREEN" "NetBox health check passed"
    else
        log "$RED" "NetBox health check failed"
        health_status=1
    fi
    
    # n8n health check
    log "$BLUE" "Checking n8n connectivity..."
    if /app/scripts/n8n-integration.sh test; then
        log "$GREEN" "n8n health check passed"
    else
        log "$RED" "n8n health check failed"
        health_status=1
    fi
    
    # Docker connectivity check
    log "$BLUE" "Checking Docker connectivity..."
    if docker info > /dev/null 2>&1; then
        log "$GREEN" "Docker connectivity check passed"
    else
        log "$RED" "Docker connectivity check failed"
        health_status=1
    fi
    
    return $health_status
}

# Test stage
run_tests() {
    log "$BLUE" "Running test suite..."
    
    local test_status=0
    
    # Validate workflow files
    log "$BLUE" "Validating n8n workflows..."
    if /app/scripts/n8n-integration.sh validate; then
        log "$GREEN" "Workflow validation passed"
    else
        log "$RED" "Workflow validation failed"
        test_status=1
    fi
    
    # Validate NetBox data
    log "$BLUE" "Validating NetBox data integrity..."
    if /app/scripts/netbox-integration.sh validate; then
        log "$GREEN" "NetBox validation passed"
    else
        log "$RED" "NetBox validation failed"
        test_status=1
    fi
    
    # Run Ansible syntax checks
    if [ -d "playbooks" ]; then
        log "$BLUE" "Running Ansible syntax checks..."
        find playbooks -name "*.yml" -o -name "*.yaml" | while read -r playbook; do
            if ansible-playbook --syntax-check "$playbook"; then
                log "$GREEN" "Ansible syntax check passed: $(basename "$playbook")"
            else
                log "$RED" "Ansible syntax check failed: $(basename "$playbook")"
                test_status=1
            fi
        done
    fi
    
    return $test_status
}

# Build stage
build_artifacts() {
    log "$BLUE" "Building deployment artifacts..."
    
    # Create deployment package
    local artifact_name="deployment_$(date +%Y%m%d_%H%M%S).tar.gz"
    local artifact_path="artifacts/$artifact_name"
    
    # Package workflows and configurations
    tar -czf "$artifact_path" \
        --exclude='*.log' \
        --exclude='node_modules' \
        --exclude='.git' \
        n8n/ netbox-data/ playbooks/ configs/ 2>/dev/null || true
    
    if [ -f "$artifact_path" ]; then
        log "$GREEN" "Deployment artifact created: $artifact_path"
        echo "ARTIFACT_PATH=$artifact_path" >> artifacts/build.env
    else
        log "$RED" "Failed to create deployment artifact"
        return 1
    fi
    
    # Generate deployment report
    cat > "reports/deployment_report.json" << EOF
{
    "build_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "environment": "$ENVIRONMENT",
    "project": "$PROJECT_NAME",
    "artifact": "$artifact_name",
    "commit_sha": "${CI_COMMIT_SHA:-unknown}",
    "pipeline_id": "${CI_PIPELINE_ID:-unknown}",
    "components": {
        "netbox": {
            "url": "$NETBOX_URL",
            "status": "$(curl -s -w "%{http_code}" -H "Authorization: Token $NETBOX_TOKEN" "$NETBOX_URL/api/status/" -o /dev/null || echo "unknown")"
        },
        "n8n": {
            "url": "$N8N_URL",
            "status": "$(curl -s -w "%{http_code}" -H "X-N8N-API-KEY: $N8N_API_KEY" "$N8N_URL/api/v1/workflows" -o /dev/null || echo "unknown")"
        }
    }
}
EOF
    
    log "$GREEN" "Build stage completed successfully"
}

# Deploy stage
deploy() {
    log "$BLUE" "Starting deployment to $ENVIRONMENT environment..."
    
    # Deploy to NetBox
    log "$BLUE" "Deploying NetBox configurations..."
    if /app/scripts/netbox-integration.sh deploy; then
        log "$GREEN" "NetBox deployment completed"
    else
        log "$RED" "NetBox deployment failed"
        return 1
    fi
    
    # Deploy n8n workflows
    log "$BLUE" "Deploying n8n workflows..."
    if /app/scripts/n8n-integration.sh deploy; then
        log "$GREEN" "n8n workflow deployment completed"
    else
        log "$RED" "n8n workflow deployment failed"
        return 1
    fi
    
    # Run post-deployment tests
    log "$BLUE" "Running post-deployment verification..."
    sleep 10  # Wait for services to stabilize
    
    if health_check; then
        log "$GREEN" "Post-deployment verification passed"
    else
        log "$RED" "Post-deployment verification failed"
        return 1
    fi
    
    # Sync NetBox with n8n
    log "$BLUE" "Synchronizing NetBox with n8n workflows..."
    /app/scripts/netbox-integration.sh sync
    
    log "$GREEN" "Deployment completed successfully"
}

# Backup stage
backup() {
    log "$BLUE" "Creating backup of current state..."
    
    # Backup n8n workflows
    /app/scripts/n8n-integration.sh backup
    
    # Create environment backup
    local backup_dir="backups/environment_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Save environment configuration
    env | grep -E "(NETBOX_|N8N_|CI_)" > "$backup_dir/environment.txt" 2>/dev/null || true
    
    # Save deployment report
    cp reports/deployment_report.json "$backup_dir/" 2>/dev/null || true
    
    log "$GREEN" "Backup completed: $backup_dir"
}

# Cleanup stage
cleanup() {
    log "$BLUE" "Running cleanup tasks..."
    
    # Clean old logs (keep last 10)
    find logs -name "*.log" -type f -printf '%T@ %p\n' | \
        sort -nr | tail -n +11 | cut -d' ' -f2- | xargs -r rm -f
    
    # Clean old artifacts (keep last 5)
    find artifacts -name "*.tar.gz" -type f -printf '%T@ %p\n' | \
        sort -nr | tail -n +6 | cut -d' ' -f2- | xargs -r rm -f
    
    # Clean old backups (keep last 7 days)
    find backups -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
    
    log "$GREEN" "Cleanup completed"
}

# Error handler
handle_error() {
    local exit_code=$1
    local line_number=$2
    log "$RED" "Pipeline failed at line $line_number with exit code $exit_code"
    
    # Generate error report
    cat > "reports/error_report.json" << EOF
{
    "error_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "exit_code": $exit_code,
    "line_number": $line_number,
    "stage": "$PIPELINE_STAGE",
    "environment": "$ENVIRONMENT",
    "project": "$PROJECT_NAME"
}
EOF
    
    # Attempt to send notification (if configured)
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🚨 Pipeline failed in $PROJECT_NAME ($ENVIRONMENT) at stage: $PIPELINE_STAGE\"}" \
            "$SLACK_WEBHOOK_URL" 2>/dev/null || true
    fi
    
    exit $exit_code
}

# Set error trap
trap 'handle_error $? $LINENO' ERR

# Main execution
main() {
    local operation="${1:-pipeline}"
    
    case "$operation" in
        "init")
            init_pipeline
            ;;
        "health")
            init_pipeline
            health_check
            ;;
        "test")
            init_pipeline
            health_check
            run_tests
            ;;
        "build")
            init_pipeline
            health_check
            run_tests
            build_artifacts
            ;;
        "deploy")
            init_pipeline
            health_check
            deploy
            ;;
        "backup")
            init_pipeline
            backup
            ;;
        "cleanup")
            cleanup
            ;;
        "pipeline"|"full")
            init_pipeline
            health_check
            run_tests
            build_artifacts
            if [ "$ENVIRONMENT" != "development" ]; then
                backup
            fi
            deploy
            cleanup
            ;;
        *)
            echo "Usage: $0 {init|health|test|build|deploy|backup|cleanup|pipeline}"
            echo "  init     - Initialize pipeline environment"
            echo "  health   - Run health checks only"
            echo "  test     - Run tests and validation"
            echo "  build    - Build deployment artifacts"
            echo "  deploy   - Deploy to target environment"
            echo "  backup   - Create backup of current state"
            echo "  cleanup  - Clean up old files"
            echo "  pipeline - Run full CI/CD pipeline (default)"
            exit 1
            ;;
    esac
    
    log "$GREEN" "Pipeline operation '$operation' completed successfully"
}

main "$@"
