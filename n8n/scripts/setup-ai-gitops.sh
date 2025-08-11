#!/bin/bash
# AI GitOps Setup Script with GitLab CI/CD Integration
# Run this from /home/dan/POC2/n8n directory

set -e

echo "🚀 Setting up AI GitOps Network Automation with GitLab CI/CD..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if we're in the right directory
if [[ ! -f "docker-compose.yml" ]]; then
    echo "❌ Please run this script from the n8n directory containing docker-compose.yml"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Create necessary directories
echo "📁 Creating required directories..."
mkdir -p {data,logs,backups,ansible-roles,network-configs}
mkdir -p monitoring/grafana/{dashboards,provisioning}

# Deploy the complete stack
echo "📦 Deploying AI GitOps automation stack..."
echo "   - n8n workflow automation"
echo "   - PostgreSQL database"
echo "   - Redis cache"
echo "   - GitLab CI/CD Runner"
echo "   - Ansible pipeline executor"
echo "   - Prometheus monitoring"
echo "   - Grafana dashboards"

docker-compose build --no-cache
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 60

# Check if n8n is running
echo "🔍 Checking service health..."
if ! curl -f http://localhost:5678 > /dev/null 2>&1; then
    echo "❌ n8n is not responding. Checking logs..."
    docker-compose logs n8n
    exit 1
fi

echo "✅ n8n is running at http://localhost:5678"

# Check other services
services=("postgres" "redis" "gitlab-runner" "prometheus" "grafana")
for service in "${services[@]}"; do
    if docker-compose ps "$service" | grep -q "Up"; then
        echo "✅ $service is running"
    else
        echo "⚠️  $service may have issues. Check with: docker-compose logs $service"
    fi
done

# GitLab Runner Registration
echo ""
echo "🔧 GitLab Runner Setup"
echo "To register the GitLab Runner with your GitLab instance:"
echo ""
echo "1. Get your GitLab registration token from:"
echo "   Project Settings > CI/CD > Runners > Project runners"
echo ""
echo "2. Run the registration command:"
echo "   export GITLAB_URL=https://gitlab.your-company.com"
echo "   export GITLAB_REGISTRATION_TOKEN=your-token-here"
echo "   ./register-gitlab-runner.sh"
echo ""

# Display access information
cat << 'EOF'

🎉 AI GitOps Network Automation Stack Deployed!

📋 Service Access:
┌─────────────────────────────────────────────────────┐
│ Service         │ URL                    │ Login     │
├─────────────────────────────────────────────────────┤
│ n8n             │ http://localhost:5678  │ admin     │
│ Grafana         │ http://localhost:3000  │ admin     │
│ Prometheus      │ http://localhost:9090  │ N/A       │
└─────────────────────────────────────────────────────┘

🔐 Default Credentials (CHANGE IMMEDIATELY):
- n8n: admin / secure_password_change_me
- Grafana: admin / admin_change_me

📊 Container Status:
EOF

docker-compose ps

cat << 'EOF'

📋 Next Steps:
1. Access n8n at http://localhost:5678
2. Change default passwords in docker-compose.yml
3. Configure environment variables in n8n:
   - OPENAI_API_KEY
   - NETBOX_URL & NETBOX_TOKEN  
   - GITLAB_URL & GITLAB_TOKEN
   - SERVICENOW_URL & SERVICENOW_AUTH
   
4. Register GitLab Runner (see instructions above)
5. Import AI GitOps workflows from: ai-gitops/workflows/
6. Follow deployment guide: ai-gitops/docs/deployment_guide.md

📁 AI GitOps Files:
   /home/dan/POC2/n8n/ai-gitops/

🔧 Management Commands:
   # View logs
   docker-compose logs -f [service-name]
   
   # Restart services
   docker-compose restart [service-name]
   
   # Update stack
   docker-compose pull && docker-compose up -d
   
   # Stop all services
   docker-compose down
   
   # Register GitLab Runner
   ./register-gitlab-runner.sh

🔍 Troubleshooting:
   # Check service status
   docker-compose ps
   
   # View service logs
   docker-compose logs [service-name]
   
   # Test network connectivity
   docker exec ansible-pipeline-executor ping google.com
   
   # Test Ansible
   docker exec ansible-pipeline-executor ansible --version

📚 Documentation:
   - Main README: ai-gitops/README.md
   - Deployment Guide: ai-gitops/docs/deployment_guide.md
   - GitLab CI Pipeline: ai-gitops/ci-cd/gitlab-ci.yml

Happy Automating! 🤖✨
EOF
