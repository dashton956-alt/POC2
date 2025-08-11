# 🔧 n8n Environment Variables Setup

## Setting Environment Variables in n8n

### Method 1: Docker Environment Variables (Recommended)

Edit your n8n docker-compose.yml to add environment variables:

```yaml
services:
  n8n:
    image: n8nio/n8n:latest
    environment:
      # NetBox Configuration
      - NETBOX_URL=http://localhost:8000
      - NETBOX_TOKEN=your-netbox-api-token-here
      
      # OpenAI Configuration
      - OPENAI_MODEL=gpt-4
      - OPENAI_CREDENTIAL_ID=openai-api-cred
      
      # Customer Configuration
      - CUSTOMER_ID=demo-corp
      - CUSTOMER_NAME=Demo Corporation
      
      # GitLab Configuration (optional)
      - GITLAB_URL=https://gitlab.com
      - GITLAB_PROJECT_ID=12345
      - GITLAB_TOKEN=your-gitlab-token
      
      # Notification Configuration (optional)
      - SLACK_CREDENTIAL_ID=slack-api-cred
      - EMAIL_CREDENTIAL_ID=smtp-cred
      - NETWORK_TEAM_EMAIL=network@company.com
      
      # ServiceNow Configuration (optional)
      - SERVICENOW_URL=https://company.service-now.com
      - SERVICENOW_USER=n8n-automation
      - SERVICENOW_PASSWORD=password
```

### Method 2: n8n Environment File

Create a `.env` file in your n8n directory:

```bash
# NetBox Integration
NETBOX_URL=http://localhost:8000
NETBOX_TOKEN=your-actual-netbox-token

# OpenAI Configuration  
OPENAI_MODEL=gpt-4
OPENAI_CREDENTIAL_ID=openai-api-cred

# Customer Settings
CUSTOMER_ID=demo-corp
CUSTOMER_NAME=Demo Corporation

# Optional Services
GITLAB_URL=https://gitlab.com
GITLAB_PROJECT_ID=12345
SLACK_CREDENTIAL_ID=slack-api-cred
```

## Quick Setup Commands

### Step 1: Get Your NetBox API Token
```bash
# Access NetBox web interface
echo "Go to: http://localhost:8000"
echo "Login → Admin → Users → [Your User] → API Tokens"
echo "Create token with read/write permissions"
```

### Step 2: Update n8n with Environment Variables
```bash
cd /home/dan/POC2/n8n

# Edit docker-compose.yml to add environment variables
nano docker-compose.yml

# Add the environment section to your n8n service
```

### Step 3: Restart n8n with New Variables
```bash
# Restart n8n to load new environment variables
docker compose restart n8n-network-automation

# Check if variables are loaded
docker compose logs n8n-network-automation | grep -i env
```

## Using Variables in Workflows

In your n8n workflows, you can now use:

### NetBox API Calls
```javascript
// URL with environment variable
{{ $env.NETBOX_URL }}/api/dcim/sites/

// Authorization header
Token {{ $env.NETBOX_TOKEN }}
```

### Dynamic Customer Configuration
```javascript
// Customer-specific webhook paths
{{ $env.CUSTOMER_ID }}-ai-gitops

// Customer name in notifications
Welcome {{ $env.CUSTOMER_NAME }}
```

### Conditional Logic
```javascript
// Use fallback values
{{ $env.NETBOX_URL || 'http://localhost:8000' }}
{{ $env.OPENAI_MODEL || 'gpt-3.5-turbo' }}
```

## Security Best Practices

### 1. Use Docker Secrets (Production)
```yaml
services:
  n8n:
    secrets:
      - netbox_token
      - openai_api_key
    environment:
      - NETBOX_TOKEN_FILE=/run/secrets/netbox_token

secrets:
  netbox_token:
    file: ./secrets/netbox_token.txt
```

### 2. Environment-Specific Files
```bash
# Development
.env.development

# Staging  
.env.staging

# Production
.env.production
```

### 3. Never Commit Secrets
```bash
# Add to .gitignore
echo "*.env" >> .gitignore
echo "secrets/" >> .gitignore
```

## Testing Environment Variables

### Test NetBox Connection
```bash
# Test if NetBox token works
curl -H "Authorization: Token ${NETBOX_TOKEN}" \
  "${NETBOX_URL}/api/dcim/sites/" | jq .
```

### Test in n8n Workflow
```javascript
// Add a test node with this expression
{
  "netbox_url": "{{ $env.NETBOX_URL }}",
  "has_token": "{{ $env.NETBOX_TOKEN ? 'Yes' : 'No' }}",
  "customer": "{{ $env.CUSTOMER_ID }}",
  "openai_model": "{{ $env.OPENAI_MODEL }}"
}
```

## Multi-Tenant Environment Variables

For multiple customers, use prefixed variables:

```bash
# Customer A
CUSTOMER_A_NETBOX_URL=https://netbox-a.company.com
CUSTOMER_A_NETBOX_TOKEN=token-a
CUSTOMER_A_GITLAB_PROJECT=123

# Customer B  
CUSTOMER_B_NETBOX_URL=https://netbox-b.company.com
CUSTOMER_B_NETBOX_TOKEN=token-b
CUSTOMER_B_GITLAB_PROJECT=456
```

Then in workflows:
```javascript
// Dynamic variable selection
{{ $env['CUSTOMER_' + $json.customer_id.toUpperCase() + '_NETBOX_URL'] }}
```

## Common Environment Variables

### Essential (Required)
- `NETBOX_URL` - NetBox API base URL
- `NETBOX_TOKEN` - NetBox API authentication token

### AI Features  
- `OPENAI_MODEL` - AI model to use (gpt-4, gpt-3.5-turbo)
- `OPENAI_CREDENTIAL_ID` - n8n credential ID for OpenAI

### Customer Management
- `CUSTOMER_ID` - Unique customer identifier
- `CUSTOMER_NAME` - Human-readable customer name

### GitOps (Optional)
- `GITLAB_URL` - GitLab instance URL
- `GITLAB_PROJECT_ID` - Project ID for automation
- `GITLAB_TOKEN` - GitLab API token

### Notifications (Optional)
- `SLACK_CREDENTIAL_ID` - n8n Slack credential ID
- `EMAIL_CREDENTIAL_ID` - n8n SMTP credential ID
- `NETWORK_TEAM_EMAIL` - Notification email address

---

**Next Step:** Apply these environment variables to your n8n setup! 🚀
