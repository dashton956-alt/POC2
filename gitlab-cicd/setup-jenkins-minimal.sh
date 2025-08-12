#!/bin/bash
# Quick and minimal Jenkins CI/CD setup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${1}[$(date '+%H:%M:%S')] $2${NC}"
}

cd "$(dirname "$0")"

log "$BLUE" "🚀 Setting up Minimal Jenkins CI/CD Pipeline"

# Check Docker
if ! command -v docker &> /dev/null; then
    log "$RED" "Docker is required but not installed"
    exit 1
fi

# Setup environment
if [ ! -f ".env" ]; then
    if [ -f ".env.jenkins" ]; then
        cp .env.jenkins .env
        log "$GREEN" "Created .env from template"
    else
        log "$YELLOW" "No .env.jenkins template found, creating minimal .env"
        cat > .env << EOF
JENKINS_ADMIN_PASSWORD=admin
NETBOX_URL=http://localhost:8000
NETBOX_TOKEN=
N8N_URL=http://localhost:5678
N8N_API_KEY=
ENVIRONMENT=development
EOF
    fi
fi

log "$BLUE" "Building minimal Jenkins container..."
docker build -f Dockerfile.jenkins.minimal -t poc2-jenkins:minimal .

log "$BLUE" "Starting Jenkins..."
docker run -d \
    --name poc2-jenkins \
    -p 8080:8080 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --env-file .env \
    poc2-jenkins:minimal

# Wait for Jenkins to start
log "$BLUE" "Waiting for Jenkins to start..."
for i in {1..30}; do
    if curl -s http://localhost:8080 > /dev/null 2>&1; then
        log "$GREEN" "✓ Jenkins is running at http://localhost:8080"
        break
    fi
    if [ $i -eq 30 ]; then
        log "$RED" "Jenkins failed to start within 30 seconds"
        exit 1
    fi
    sleep 2
done

log "$GREEN" "🎉 Minimal Jenkins setup completed!"
echo ""
log "$BLUE" "Access Jenkins at: http://localhost:8080"
log "$BLUE" "Username: admin"
log "$BLUE" "Password: $(grep JENKINS_ADMIN_PASSWORD .env | cut -d'=' -f2)"
echo ""
log "$BLUE" "Next steps:"
echo "1. Access Jenkins and create your first pipeline job"
echo "2. Use the scripts in /opt/ci-scripts/ for automation"
echo "3. Add your NetBox API token to the .env file"
echo ""
log "$BLUE" "To stop: docker stop poc2-jenkins"
log "$BLUE" "To remove: docker rm poc2-jenkins"
