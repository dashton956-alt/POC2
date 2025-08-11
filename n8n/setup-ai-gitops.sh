#!/bin/bash
# AI GitOps Setup Script
# Run this from /home/dan/POC2/n8n directory

set -e

echo "🚀 Setting up AI GitOps Network Automation..."

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

# Deploy n8n
echo "📦 Deploying n8n container..."
docker-compose up -d

# Wait for n8n to be ready
echo "⏳ Waiting for n8n to start..."
sleep 30

# Check if n8n is running
if ! curl -f http://localhost:5678 > /dev/null 2>&1; then
    echo "❌ n8n is not responding. Check docker-compose logs"
    docker-compose logs n8n
    exit 1
fi

echo "✅ n8n is running at http://localhost:5678"

# Display next steps
cat << 'EOF'

🎉 AI GitOps Setup Complete!

📋 Next Steps:
1. Access n8n at http://localhost:5678
2. Login with credentials from docker-compose.yml
3. Configure environment variables:
   - OPENAI_API_KEY
   - NETBOX_URL & NETBOX_TOKEN  
   - GITLAB_URL & GITLAB_TOKEN
   - SERVICENOW_URL & SERVICENOW_AUTH
   
4. Import workflow from: ai-gitops/workflows/
5. Follow the deployment guide: ai-gitops/docs/deployment_guide.md

📁 AI GitOps Files Location:
   /home/dan/POC2/n8n/ai-gitops/

🔧 Configuration Files:
   - Workflows: ai-gitops/workflows/
   - Templates: ai-gitops/templates/
   - Documentation: ai-gitops/docs/
   - CI/CD: ai-gitops/ci-cd/

📚 Documentation:
   - Main README: ai-gitops/README.md
   - Deployment Guide: ai-gitops/docs/deployment_guide.md
   - Architecture: ai-gitops/docs/ai_gitops_network_automation.md

Happy Automating! 🤖
EOF
