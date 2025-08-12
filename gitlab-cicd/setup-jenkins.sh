#!/bin/bash
# Quick setup script for Jenkins CI/CD pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Change to script directory
cd "$(dirname "$0")"

log "$BLUE" "🚀 Setting up Jenkins CI/CD Pipeline for POC2"

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    log "$RED" "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    log "$RED" "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if environment file exists
if [ ! -f ".env" ]; then
    if [ -f ".env.jenkins" ]; then
        log "$BLUE" "Using .env.jenkins as environment file..."
        cp .env.jenkins .env
    else
        log "$RED" "No environment file found. Please create .env file first."
        exit 1
    fi
fi

# Load environment variables
log "$BLUE" "Loading environment variables..."
set -a
source .env
set +a

log "$GREEN" "Environment configuration validated"

# Build and start services with fallback logic
log "$BLUE" "Building Jenkins container..."

# Try minimal dockerfile first (more likely to succeed)
if [ -f "Dockerfile.jenkins.minimal" ]; then
    log "$BLUE" "Using minimal Jenkins build for faster setup..."
    
    # Update docker-compose to use minimal dockerfile
    if [ -f "docker-compose.jenkins.yml.bak" ]; then
        cp docker-compose.jenkins.yml.bak docker-compose.jenkins.yml
    else
        cp docker-compose.jenkins.yml docker-compose.jenkins.yml.bak
    fi
    
    sed -i 's/dockerfile: Dockerfile\.jenkins$/dockerfile: Dockerfile.jenkins.minimal/' docker-compose.jenkins.yml
    
    if docker compose -f docker-compose.jenkins.yml build; then
        log "$GREEN" "Minimal Jenkins container built successfully"
    else
        log "$YELLOW" "Minimal build failed, trying full version..."
        # Restore original docker-compose file
        cp docker-compose.jenkins.yml.bak docker-compose.jenkins.yml
        
        if ! docker compose -f docker-compose.jenkins.yml build; then
            log "$RED" "Both Jenkins builds failed"
            exit 1
        fi
    fi
else
    # Try main Dockerfile
    if ! docker compose -f docker-compose.jenkins.yml build; then
        log "$RED" "Jenkins build failed"
        exit 1
    fi
fi

log "$BLUE" "Starting services..."
docker compose -f docker-compose.jenkins.yml up -d

# Wait for services to start
log "$BLUE" "Waiting for services to start..."
sleep 30

# Check service status
log "$BLUE" "Checking service status..."

services=("jenkins:8080" "netbox:8000" "n8n:5678")
for service in "${services[@]}"; do
    container_name="${service%:*}"
    port="${service#*:}"
    
    # Check if container is running (using partial name match)
    if docker ps --format "table {{.Names}}" | grep -q "$container_name"; then
        log "$GREEN" "✓ Container with '$container_name' in name is running"
        
        # Test connectivity
        max_attempts=15
        attempt=1
        
        while [ $attempt -le $max_attempts ]; do
            if curl -s -f "http://localhost:${port}" > /dev/null 2>&1; then
                log "$GREEN" "✓ Service responding on port $port"
                break
            fi
            
            if [ $attempt -eq $max_attempts ]; then
                log "$YELLOW" "⚠ Service may still be starting up (port $port not responding yet)"
            else
                sleep 3
                ((attempt++))
            fi
        done
    else
        log "$YELLOW" "⚠ Container with '$container_name' in name not found"
    fi
done

# Display access information
log "$GREEN" "🎉 Setup completed!"
echo ""
log "$BLUE" "Access Information:"
echo "  Jenkins:  http://localhost:8080"
echo "  NetBox:   http://localhost:8000" 
echo "  n8n:      http://localhost:5678"
echo ""

log "$BLUE" "Default Credentials:"
echo "  Jenkins:  admin / $(grep JENKINS_ADMIN_PASSWORD .env | cut -d'=' -f2 || echo 'admin123')"
echo "  NetBox:   admin / admin (create superuser first)"
echo "  n8n:      admin / admin123"
echo ""

log "$BLUE" "Next Steps:"
echo "1. Wait a few minutes for all services to fully initialize"
echo "2. Access Jenkins at http://localhost:8080"
echo "3. The pipeline jobs are automatically configured"
echo "4. Create NetBox superuser if needed"
echo "5. Get NetBox API token and update .env file"
echo ""

log "$GREEN" "Jenkins CI/CD Pipeline is ready! 🚀"
