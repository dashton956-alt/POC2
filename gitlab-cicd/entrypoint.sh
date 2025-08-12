#!/bin/bash
set -e

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Initialize GitLab Runner if not already configured
if [ ! -f /etc/gitlab-runner/config.toml ]; then
    log "Initializing GitLab Runner configuration..."
    
    # Register runner if environment variables are provided
    if [ -n "$GITLAB_URL" ] && [ -n "$REGISTRATION_TOKEN" ]; then
        log "Registering GitLab Runner..."
        gitlab-runner register \
            --non-interactive \
            --url "$GITLAB_URL" \
            --registration-token "$REGISTRATION_TOKEN" \
            --executor docker \
            --description "NetBox-n8n-CI/CD-Pipeline" \
            --docker-image "alpine:latest" \
            --docker-privileged=true \
            --docker-volumes="/var/run/docker.sock:/var/run/docker.sock" \
            --tag-list "netbox,n8n,automation,docker" \
            --run-untagged=true \
            --locked=false
    else
        log "GitLab Runner registration skipped (missing GITLAB_URL or REGISTRATION_TOKEN)"
    fi
fi

# Start GitLab Runner
log "Starting GitLab Runner..."
exec gitlab-runner run --user=gitlab-runner --working-directory=/var/lib/gitlab-runner
