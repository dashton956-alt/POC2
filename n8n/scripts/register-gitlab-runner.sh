#!/bin/bash
# GitLab Runner Registration Script

set -e

echo "🔧 GitLab Runner Registration for Network Automation"

# Check if required environment variables are set
if [[ -z "$GITLAB_URL" || -z "$GITLAB_REGISTRATION_TOKEN" ]]; then
    echo "❌ Please set GITLAB_URL and GITLAB_REGISTRATION_TOKEN environment variables"
    echo "   export GITLAB_URL=https://gitlab.your-company.com"
    echo "   export GITLAB_REGISTRATION_TOKEN=your-project-registration-token"
    exit 1
fi

echo "📋 Registering GitLab Runner..."
echo "   GitLab URL: $GITLAB_URL"
echo "   Container: gitlab-runner-network-automation"

# Register the runner
docker exec gitlab-runner-network-automation gitlab-runner register \
  --non-interactive \
  --url "$GITLAB_URL" \
  --registration-token "$GITLAB_REGISTRATION_TOKEN" \
  --executor docker \
  --docker-image "python:3.11-slim" \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
  --docker-volumes "/opt/ai-gitops:/opt/ai-gitops:ro" \
  --docker-network-mode "n8n_n8n-network" \
  --description "Network Automation AI GitOps Runner" \
  --tag-list "network-automation,ansible,ai-gitops,docker" \
  --run-untagged="false" \
  --locked="false" \
  --access-level="not_protected"

echo "✅ GitLab Runner registered successfully!"

echo "📊 Runner status:"
docker exec gitlab-runner-network-automation gitlab-runner status

echo "🔍 Available runners:"
docker exec gitlab-runner-network-automation gitlab-runner list

echo ""
echo "🎯 Next steps:"
echo "1. Verify runner appears in your GitLab project: Settings > CI/CD > Runners"
echo "2. Test the pipeline by pushing a commit with the GitLab CI configuration"
echo "3. Check runner logs: docker logs gitlab-runner-network-automation"
