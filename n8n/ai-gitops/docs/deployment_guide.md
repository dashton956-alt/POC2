# AI GitOps Network Automation - Deployment Guide

## Overview

This guide will help you deploy the complete AI-powered GitOps network automation solution, from basic n8n setup to full enterprise integration with NetBox, GitLab, ServiceNow, and AI services.

## Prerequisites

### Infrastructure Requirements
- Docker & Docker Compose
- GitLab instance with CI/CD runners
- NetBox instance for network inventory
- ServiceNow instance for change management
- OpenAI API access (or Claude/other AI service)
- Network devices with API/SSH access
- Ansible control node

### Access Requirements
- GitLab API tokens with repository and pipeline permissions
- NetBox API tokens with read/write access
- ServiceNow API credentials with change request permissions
- OpenAI API key with sufficient credits
- Network device credentials (SSH keys or username/password)

## Phase 1: Basic n8n Deployment

### 1.1 Deploy n8n Container

```bash
# Create project directory
mkdir -p /opt/network-automation/{n8n,data,backups}
cd /opt/network-automation

# Create the Dockerfile
cat > n8n/Dockerfile << 'EOF'
FROM n8nio/n8n:latest

# Install additional packages for network automation
USER root
RUN apk add --no-cache python3 py3-pip openssh-client
RUN pip3 install netmiko paramiko napalm requests

# Switch back to n8n user
USER node

EXPOSE 5678
CMD ["n8n"]
EOF

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  n8n:
    build: ./n8n
    container_name: n8n-network-automation
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=secure_password_change_me
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://your-server:5678
      - N8N_METRICS=true
      - N8N_LOG_LEVEL=info
    volumes:
      - ./data:/home/node/.n8n
      - ./backups:/opt/backups
    networks:
      - n8n-network

  # Optional: Add database for production
  postgres:
    image: postgres:13
    container_name: n8n-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: n8n
      POSTGRES_USER: n8n
      POSTGRES_PASSWORD: n8n_db_password_change_me
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - n8n-network

networks:
  n8n-network:
    driver: bridge

volumes:
  postgres_data:
EOF

# Deploy
docker-compose up -d

# Check status
docker-compose logs -f n8n
```

### 1.2 Initial n8n Configuration

1. Access n8n at `http://your-server:5678`
2. Login with admin/secure_password_change_me
3. Configure environment variables:

```bash
# Environment Variables in n8n Settings > Environments
OPENAI_API_KEY=your-openai-api-key
NETBOX_URL=https://your-netbox-instance.com
NETBOX_TOKEN=your-netbox-api-token
GITLAB_URL=https://gitlab.your-company.com
GITLAB_TOKEN=your-gitlab-api-token
PROJECT_ID=123
SERVICENOW_URL=https://your-instance.service-now.com
SERVICENOW_AUTH=base64(username:password)
NETWORK_TEAM_LEAD_ID=123
SENIOR_NETWORK_ENGINEER_ID=456
SECURITY_REVIEWER_ID=789
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
TEAMS_WEBHOOK_URL=https://company.webhook.office.com/...
```

## Phase 2: NetBox Integration

### 2.1 NetBox Setup

```bash
# If you need to deploy NetBox
git clone https://github.com/netbox-community/netbox-docker.git
cd netbox-docker

# Configure environment
cp env/netbox.env.example env/netbox.env
cp env/postgres.env.example env/postgres.env
cp env/redis.env.example env/redis.env

# Edit configuration
nano env/netbox.env
# Set ALLOWED_HOSTS, SECRET_KEY, etc.

# Deploy NetBox
docker-compose up -d

# Create superuser
docker-compose exec netbox python manage.py createsuperuser
```

### 2.2 NetBox Data Structure

Set up your NetBox with this structure:

```python
# Example NetBox API calls to create basic structure

import requests

NETBOX_URL = "https://your-netbox.com"
HEADERS = {
    "Authorization": "Token your-api-token",
    "Content-Type": "application/json"
}

# Create sites
sites_data = [
    {"name": "NYC_HQ", "slug": "nyc-hq", "status": "active"},
    {"name": "LA_Branch", "slug": "la-branch", "status": "active"},
]

for site in sites_data:
    requests.post(f"{NETBOX_URL}/api/dcim/sites/", json=site, headers=HEADERS)

# Create device roles
roles_data = [
    {"name": "Switch", "slug": "switch", "color": "2196f3"},
    {"name": "Router", "slug": "router", "color": "4caf50"},
]

for role in roles_data:
    requests.post(f"{NETBOX_URL}/api/dcim/device-roles/", json=role, headers=HEADERS)

# Create device types
device_types_data = [
    {"manufacturer": 1, "model": "C9300-48P", "slug": "c9300-48p"},
    {"manufacturer": 1, "model": "ISR4331", "slug": "isr4331"},
]

for device_type in device_types_data:
    requests.post(f"{NETBOX_URL}/api/dcim/device-types/", json=device_type, headers=HEADERS)
```

## Phase 3: GitLab Repository Setup

### 3.1 Create Network Automation Repository

```bash
# Create new GitLab repository
# Repository structure:
mkdir -p network-automation-repo/{playbooks,inventories,group_vars,tests,rollback,backups}
cd network-automation-repo

# Initialize repository
git init
git remote add origin https://gitlab.your-company.com/network/automation.git

# Create base structure
cat > README.md << 'EOF'
# Network Automation Repository

AI-generated Ansible playbooks for network infrastructure automation.

## Structure
- `playbooks/` - Ansible playbooks organized by TFS number
- `inventories/` - Device inventory files per change
- `group_vars/` - Variable files for different environments  
- `tests/` - Validation and testing playbooks
- `rollback/` - Rollback playbooks for each change
- `backups/` - Configuration backups

## Usage
This repository is automatically managed by the n8n AI GitOps workflow.
Manual changes should follow the standard change management process.
EOF

# Add GitLab CI/CD pipeline
cp /path/to/gitlab-ci.yml .gitlab-ci.yml

# Create base Ansible configuration
cat > ansible.cfg << 'EOF'
[defaults]
host_key_checking = False
retry_files_enabled = False
stdout_callback = yaml
log_path = /var/log/ansible.log
inventory = inventories/
roles_path = roles/
vault_password_file = .vault_pass

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null
pipelining = True
EOF

# Create requirements file
cat > requirements.yml << 'EOF'
---
collections:
  - name: cisco.ios
  - name: ansible.netcommon
  - name: community.network
  - name: ansible.posix
EOF

git add .
git commit -m "Initial repository setup"
git push -u origin main
```

### 3.2 Configure GitLab CI/CD Variables

In GitLab Project Settings > CI/CD > Variables, add:

```bash
# Ansible credentials
ANSIBLE_VAULT_PASSWORD
NETWORK_SSH_KEY
NETWORK_USERNAME
NETWORK_PASSWORD

# External integrations
SERVICENOW_URL
SERVICENOW_AUTH
SLACK_WEBHOOK_URL
TEAMS_WEBHOOK_URL
PAGERDUTY_INTEGRATION_KEY

# Environment-specific
STAGING_INVENTORY_PATH
PRODUCTION_INVENTORY_PATH
```

## Phase 4: ServiceNow Integration

### 4.1 ServiceNow Configuration

1. **Create Integration User**:
   - Create dedicated service account for API access
   - Assign roles: `itil`, `rest_service`, `change_manager`

2. **Configure Change Request Table**:
   ```javascript
   // Business Rule to auto-approve AI-generated changes (optional)
   if (current.requested_by.name == 'network-automation-system' && 
       current.risk == 'Low') {
       current.state = 3; // Auto-approve low-risk changes
   }
   ```

3. **Create Custom Fields** (if needed):
   - `u_tfs_number` - Text field for TFS tracking
   - `u_automation_type` - Choice field (AI-Generated, Manual)
   - `u_gitlab_pipeline` - URL field for pipeline links

## Phase 5: AI Service Setup

### 5.1 OpenAI Configuration

```bash
# Test OpenAI API access
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer your-api-key"

# Set up usage monitoring
# Create alerts for quota usage
```

### 5.2 Alternative AI Services

If using Claude or other services, update the n8n workflow nodes accordingly:

```javascript
// Claude API example
const response = await $http.request({
  method: 'POST',
  url: 'https://api.anthropic.com/v1/messages',
  headers: {
    'Authorization': `Bearer ${$env.CLAUDE_API_KEY}`,
    'Content-Type': 'application/json',
    'anthropic-version': '2023-06-01'
  },
  body: {
    model: 'claude-3-sonnet-20240229',
    max_tokens: 4000,
    messages: [{ role: 'user', content: playbookPrompt }]
  }
});
```

## Phase 6: n8n Workflow Implementation

### 6.1 Import Workflow

1. In n8n, go to Workflows > Import from File
2. Import the workflow configuration from `n8n_ai_gitops_workflow_implementation.md`
3. Configure each node with your specific endpoints and credentials
4. Test individual nodes before connecting the full workflow

### 6.2 Test Workflow Components

```bash
# Test each integration individually:

# 1. Test NetBox connectivity
curl -H "Authorization: Token your-token" \
     https://your-netbox.com/api/dcim/devices/

# 2. Test GitLab API
curl -H "Authorization: Bearer your-token" \
     https://gitlab.your-company.com/api/v4/projects

# 3. Test ServiceNow API  
curl -H "Authorization: Basic base64(user:pass)" \
     https://your-instance.service-now.com/api/now/table/change_request

# 4. Test OpenAI API
curl https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer your-key" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4","messages":[{"role":"user","content":"Hello"}]}'
```

## Phase 7: Security Hardening

### 7.1 Network Security

```bash
# Firewall rules (example for iptables)
iptables -A INPUT -p tcp --dport 5678 -s trusted-network/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 5678 -j DROP

# SSL/TLS Configuration
# Set up reverse proxy with nginx
cat > nginx.conf << 'EOF'
server {
    listen 443 ssl;
    server_name n8n.your-company.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF
```

### 7.2 Credential Management

```bash
# Use Ansible Vault for sensitive data
ansible-vault create group_vars/all/vault.yml

# Store network device credentials securely
cat > group_vars/all/vault.yml << 'EOF'
vault_network_username: admin
vault_network_password: secure_password
vault_enable_password: enable_password
EOF

# Encrypt the vault
ansible-vault encrypt group_vars/all/vault.yml
```

## Phase 8: Monitoring & Alerting

### 8.1 n8n Monitoring

```yaml
# docker-compose.yml addition for monitoring
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      
  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

### 8.2 Log Management

```bash
# Configure log forwarding
docker-compose logs n8n | logger -t n8n-automation

# Set up log rotation
cat > /etc/logrotate.d/n8n-automation << 'EOF'
/var/log/n8n-automation.log {
    daily
    rotate 30
    compress
    missingok
    notifempty
    create 644 root root
}
EOF
```

## Phase 9: Testing & Validation

### 9.1 End-to-End Testing

```bash
# Test complete workflow with sample data
curl -X POST http://n8n.your-company.com:5678/webhook/network-automation \
  -H "Content-Type: application/json" \
  -d '{
    "user_request": "Create VLAN 100 for Sales team in NYC office",
    "requested_by": "john.doe@company.com",
    "priority": "medium"
  }'
```

### 9.2 Rollback Testing

```bash
# Test rollback procedures
ansible-playbook rollback/TFS123456/rollback.yml -i inventories/TFS123456/hosts.yml --check
```

## Phase 10: Production Rollout

### 10.1 Gradual Deployment

1. **Week 1**: Deploy to development environment
2. **Week 2**: Test with non-critical network changes
3. **Week 3**: Expand to staging environment
4. **Week 4**: Limited production rollout
5. **Week 5**: Full production deployment

### 10.2 User Training

1. **Network Engineers**: n8n workflow management
2. **Operations Team**: Monitoring and troubleshooting
3. **Change Management**: New approval processes
4. **Security Team**: Security monitoring and compliance

## Troubleshooting Guide

### Common Issues

1. **n8n Workflow Failures**:
   ```bash
   # Check logs
   docker-compose logs n8n
   
   # Check node execution
   # Use n8n GUI to examine failed nodes
   ```

2. **API Integration Issues**:
   ```bash
   # Test individual API endpoints
   # Check authentication tokens
   # Verify network connectivity
   ```

3. **Ansible Execution Failures**:
   ```bash
   # Check GitLab CI/CD logs
   # Verify device connectivity
   # Test playbooks manually
   ```

### Recovery Procedures

1. **Emergency Stop**: Disable n8n webhook to stop new changes
2. **Manual Rollback**: Execute rollback playbooks manually
3. **Service Recovery**: Restart services in dependency order

## Maintenance

### Regular Tasks

- **Weekly**: Review generated playbooks and approvals
- **Monthly**: Update AI prompts and templates
- **Quarterly**: Security audit and credential rotation
- **Annually**: Architecture review and optimization

This deployment guide provides a complete roadmap for implementing your AI-powered GitOps network automation solution. Start with Phase 1 and gradually progress through each phase to build a robust, enterprise-grade automation platform.
