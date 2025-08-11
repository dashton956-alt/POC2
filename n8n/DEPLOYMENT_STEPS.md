# 🚀 AI GitOps Pipeline - Complete Deployment Steps

## Phase 1: Prerequisites & Environment Setup

### Step 1: Verify Services are Running
```bash
# Check all services are up
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Expected services:
# ✅ n8n-network-automation (port 5678)
# ✅ netbox-docker-netbox-1 (port 8000)
# ✅ n8n-postgres (database persistence)
```

### Step 2: Access n8n Web Interface
```bash
# Open in browser
http://localhost:5678

# Create admin account if first time:
# Username: admin
# Password: [choose secure password]
```

### Step 3: Set Up Required n8n Credentials
Access n8n → Settings → Credentials → Add New

#### OpenAI API (Required for AI features)
```
Name: OpenAI API
Type: OpenAI
API Key: [your-openai-api-key]
```

#### GitLab API (Required for GitOps)
```
Name: GitLab API  
Type: GitLab API
Access Token: [your-gitlab-token]
GitLab Server: https://gitlab.com (or your GitLab URL)
```

#### Slack API (Optional - for notifications)
```
Name: Slack API
Type: Slack API
Access Token: [your-slack-bot-token]
```

#### SMTP Email (Optional - for notifications)
```
Name: SMTP Email
Type: SMTP
Host: [your-smtp-server]
Port: 587
User: [your-email]
Password: [your-email-password]
```

### Step 4: Get NetBox API Token
```bash
# Access NetBox
http://localhost:8000

# Login with superuser account
# Go to: Admin → Users → [your-user] → API Tokens
# Create new token with read/write permissions
# Copy the token for later use
```

## Phase 2: Deploy First Customer

### Step 5: Configure Customer Environment
```bash
cd /home/dan/POC2/n8n

# Deploy first customer (demo)
./deploy-ai-gitops.sh deploy-customer "demo-corp" "Demo Corporation" "http://localhost:8000" "1"
```

### Step 6: Configure Customer Credentials
```bash
# Edit the generated environment file
nano credentials/demo-corp.env

# Add your actual credentials:
NETBOX_TOKEN=your-netbox-api-token-here
GITLAB_TOKEN=your-gitlab-access-token-here
OPENAI_API_KEY=your-openai-api-key-here
```

### Step 7: Import Workflow into n8n
```bash
# The deployment script will show you the workflow ID
# Copy the template content and import via n8n web interface

# Alternative: Use n8n API to import directly
curl -X POST http://localhost:5678/api/v1/workflows \
  -H "Content-Type: application/json" \
  -d @workflows/templates/ai-gitops-network-automation-template.json
```

## Phase 3: Configure GitLab Repository

### Step 8: Create GitLab Project
```bash
# Create new GitLab project for network automation
# Project name: "network-automation-gitops"
# Initialize with README
# Get the project ID from the URL or settings
```

### Step 9: Set Up GitLab CI/CD Variables
In GitLab project → Settings → CI/CD → Variables:
```
NETBOX_URL=http://localhost:8000
NETBOX_TOKEN=[your-netbox-token]
ANSIBLE_VAULT_PASSWORD=[secure-password]
```

## Phase 4: Test the Complete Pipeline

### Step 10: Test Customer Deployment
```bash
# Test the customer deployment
./deploy-ai-gitops.sh test-customer "demo-corp"
```

### Step 11: Test AI GitOps Webhook
```bash
# Test with natural language request
curl -X POST http://localhost:5678/webhook/demo-corp-ai-gitops \
  -H "Content-Type: application/json" \
  -H "X-Customer-ID: demo-corp" \
  -d '{
    "user_request": "Create VLAN 100 for Marketing team in London office",
    "requester": "test@demo-corp.com",
    "urgency": "medium"
  }'
```

### Step 12: Test with Structured Data
```bash
# Test with structured form data
curl -X POST http://localhost:5678/webhook/demo-corp-ai-gitops \
  -H "Content-Type: application/json" \
  -H "X-Customer-ID: demo-corp" \
  -d '{
    "intent_type": "structured",
    "action_type": "create",
    "resource_type": "vlan",
    "parameters": {
      "vlan_id": 200,
      "vlan_name": "Sales",
      "location": "NYC",
      "description": "Sales team VLAN"
    },
    "urgency": "high",
    "requester": "admin@demo-corp.com"
  }'
```

## Phase 5: Multi-Customer Deployment

### Step 13: Add Second Customer
```bash
# Deploy another customer
./deploy-ai-gitops.sh deploy-customer "acme-corp" "ACME Corporation" "https://netbox.acme.com" "2"

# Configure their credentials
nano credentials/acme-corp.env
```

### Step 14: List All Customers
```bash
# View all deployed customers
./deploy-ai-gitops.sh list-customers
```

## Phase 6: Monitor & Validate

### Step 15: Check n8n Executions
```bash
# Access n8n web interface
http://localhost:5678

# Go to Executions tab to see workflow runs
# Check for successful/failed executions
```

### Step 16: Monitor NetBox Integration
```bash
# Check NetBox API connectivity
curl -H "Authorization: Token your-netbox-token" \
  http://localhost:8000/api/dcim/sites/

# Should return site data in JSON format
```

### Step 17: Validate GitLab Integration
```bash
# Check GitLab project for:
# ✅ New branches created by AI
# ✅ Ansible playbooks committed
# ✅ Merge requests opened
# ✅ CI/CD pipelines triggered
```

## Phase 7: Production Readiness

### Step 18: Set Up Monitoring
```bash
# Access Grafana dashboard
http://localhost:3000

# Import n8n monitoring dashboard
# Monitor workflow execution rates, errors, performance
```

### Step 19: Configure Alerting
```bash
# Set up Prometheus alerts for:
# - Workflow failures
# - API rate limits
# - Database connectivity issues
# - NetBox sync problems
```

### Step 20: Security Hardening
```bash
# Change default passwords
# Enable HTTPS/TLS
# Configure firewall rules
# Set up backup procedures
# Implement log rotation
```

## Expected Results

After completing these steps, you should have:

✅ **Fully functional AI GitOps pipeline**
✅ **Multi-tenant n8n deployment**  
✅ **Natural language → Network automation**
✅ **GitLab integration with CI/CD**
✅ **NetBox data synchronization**
✅ **Automated Ansible playbook generation**
✅ **Enterprise approval workflows**
✅ **Multi-channel notifications**
✅ **Audit trails and compliance**
✅ **Monitoring and alerting**

## Troubleshooting Commands

```bash
# Check n8n logs
docker logs n8n-network-automation -f

# Check NetBox logs  
docker logs netbox-docker-netbox-1 -f

# Test API connectivity
curl -I http://localhost:5678/healthz
curl -I http://localhost:8000/api/

# Restart services if needed
cd /home/dan/POC2/n8n && docker compose restart
cd /home/dan/POC2/netbox-docker && docker compose restart
```

---

**Status:** Ready for deployment 🚀  
**Next Step:** Execute Phase 1, Step 1 ⬆️
