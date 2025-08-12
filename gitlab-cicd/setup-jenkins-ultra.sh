#!/bin/bash
# Ultra-minimal Jenkins setup script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

cd "$(dirname "$0")"

log "$BLUE" "🚀 Setting up Ultra-Minimal Jenkins CI/CD Pipeline"

# Check Docker
if ! command -v docker &> /dev/null; then
    log "$RED" "Docker is required but not installed"
    exit 1
fi

# Use environment file
if [ ! -f ".env" ]; then
    if [ -f ".env.jenkins" ]; then
        cp .env.jenkins .env
        log "$BLUE" "Using .env.jenkins as environment"
    fi
fi

# Try ultra-minimal build first
log "$BLUE" "Building ultra-minimal Jenkins container..."

# Create a simple docker-compose for ultra-minimal
cat > docker-compose.ultra-minimal.yml << 'EOF'
version: '3.8'

services:
  jenkins:
    build:
      context: .
      dockerfile: Dockerfile.jenkins.ultra-minimal
    container_name: poc2-jenkins-minimal
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock:ro
    env_file:
      - .env
    restart: unless-stopped

volumes:
  jenkins_home:
EOF

if docker compose -f docker-compose.ultra-minimal.yml build; then
    log "$GREEN" "Ultra-minimal Jenkins built successfully!"
    
    log "$BLUE" "Starting Jenkins..."
    docker compose -f docker-compose.ultra-minimal.yml up -d
    
    log "$BLUE" "Waiting for Jenkins to start..."
    sleep 30
    
    log "$GREEN" "🎉 Jenkins is starting up!"
    echo ""
    log "$BLUE" "Access Jenkins at: http://localhost:8080"
    echo ""
    log "$YELLOW" "Default credentials:"
    echo "  Username: admin"
    echo "  Password: $(grep JENKINS_ADMIN_PASSWORD .env 2>/dev/null | cut -d'=' -f2 || echo 'admin123')"
    echo ""
    log "$BLUE" "Useful commands:"
    echo "  View logs: docker compose -f docker-compose.ultra-minimal.yml logs -f"
    echo "  Stop: docker compose -f docker-compose.ultra-minimal.yml down"
    echo ""
    log "$GREEN" "Jenkins CI/CD Pipeline is ready! 🚀"
else
    log "$RED" "Ultra-minimal build failed too. Let's try without any custom packages."
    
    # Fallback to pure Jenkins
    cat > docker-compose.pure.yml << 'EOF'
version: '3.8'

services:
  jenkins:
    image: jenkins/jenkins:2.426.1-lts
    container_name: poc2-jenkins-pure
    ports:
      - "8080:8080" 
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
    environment:
      - JENKINS_ADMIN_PASSWORD=admin123
    restart: unless-stopped

volumes:
  jenkins_home:
EOF
    
    log "$BLUE" "Starting pure Jenkins container..."
    docker compose -f docker-compose.pure.yml up -d
    
    log "$GREEN" "🎉 Pure Jenkins started!"
    echo ""
    log "$BLUE" "Access Jenkins at: http://localhost:8080"
    echo "  Username: admin"
    echo "  Password: admin123"
    echo ""
    log "$BLUE" "You can configure pipelines manually through the web interface."
fi
