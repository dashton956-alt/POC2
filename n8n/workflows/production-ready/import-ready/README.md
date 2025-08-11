# 📦 n8n Workflow Import Package

## 🎯 Quick Import Guide

This package contains 8 production-ready n8n workflows optimized for network automation with NetBox integration and AI GitOps capabilities.

## 📋 Import Order (Recommended)

### 1. **Foundation Setup** (Import First)
```
1. environment-variables-test.json    # Test environment setup
2. netbox-connection-test.json        # Validate NetBox connectivity
```

### 2. **Core NetBox Workflows**
```
3. netbox-device-discovery.json       # Automated device monitoring
4. netbox-ipam-management.json        # IP address management API
5. netbox-compliance-monitor.json     # Network compliance checking
```

### 3. **Advanced Automation**
```
6. multi-tenant-netbox-router.json    # Customer routing & isolation
7. quick-start-ai-network.json        # Simple AI network automation
8. ai-gitops-automation-complete.json # Full enterprise AI GitOps pipeline
```

## 🚀 One-Click Import Process

### Method 1: Individual Import
1. Open n8n at `http://localhost:5678`
2. Go to **Workflows** → **Import from File**
3. Select any `.json` file from this directory
4. Click **Import** → **Save**

### Method 2: Batch Import Script
```bash
# Run from POC2 directory
./n8n/import-ready/batch-import.sh
```

## ⚙️ Prerequisites

### Environment Variables Required
```bash
# In your docker-compose.yml or .env file:
NETBOX_URL=http://localhost:8000
NETBOX_TOKEN=your_netbox_api_token_here
CUSTOMER_ID=default
OPENAI_API_KEY=your_openai_key_here
GITLAB_URL=https://gitlab.com
GITLAB_TOKEN=your_gitlab_token_here
SLACK_WEBHOOK_URL=https://hooks.slack.com/...
```

### n8n Credentials Setup
1. **NetBox Credential**:
   - Name: `netbox`
   - Type: HTTP Header Auth
   - Header Name: `Authorization`
   - Header Value: `Token YOUR_NETBOX_TOKEN`

2. **OpenAI Credential**:
   - Name: `openai`
   - Type: HTTP Header Auth
   - Header Name: `Authorization`
   - Header Value: `Bearer YOUR_OPENAI_KEY`

## 🔧 Workflow Descriptions

### 🧪 Testing & Validation
- **environment-variables-test.json**: Validates environment variables and connectivity
- **netbox-connection-test.json**: Tests NetBox API authentication and basic queries

### 🔍 NetBox Integration
- **netbox-device-discovery.json**: Discovers and monitors devices every 15 minutes
- **netbox-ipam-management.json**: REST API for IP address lifecycle management
- **netbox-compliance-monitor.json**: Compliance checking with automated reporting

### 🏢 Multi-Tenant & Routing
- **multi-tenant-netbox-router.json**: Routes requests to customer-specific NetBox instances
- **quick-start-ai-network.json**: Simple AI-powered network automation
- **ai-gitops-automation-complete.json**: Full enterprise GitOps pipeline with AI

## 📊 Workflow Features Matrix

| Workflow | Environment Variables | Multi-Tenant | AI Integration | GitOps | Webhooks |
|----------|----------------------|---------------|----------------|---------|----------|
| Environment Test | ✅ | ❌ | ❌ | ❌ | ✅ |
| NetBox Connection | ✅ | ❌ | ❌ | ❌ | ❌ |
| Device Discovery | ✅ | ❌ | ❌ | ❌ | ❌ |
| IPAM Management | ✅ | ❌ | ❌ | ❌ | ✅ |
| Compliance Monitor | ✅ | ❌ | ❌ | ❌ | ❌ |
| Multi-Tenant Router | ✅ | ✅ | ❌ | ❌ | ✅ |
| Quick AI Network | ✅ | ❌ | ✅ | ❌ | ✅ |
| AI GitOps Complete | ✅ | ✅ | ✅ | ✅ | ✅ |

## 🎛️ Activation Instructions

After importing workflows:

1. **Enable Environment Variables**: Ensure all `$env.*` variables are set in docker-compose.yml
2. **Configure Credentials**: Set up NetBox and OpenAI credentials in n8n
3. **Activate Workflows**: Toggle "Active" switch for each imported workflow
4. **Test Webhooks**: Use the provided test URLs to validate functionality

## 🔗 Webhook Endpoints (After Activation)

```
Environment Test:     http://localhost:5678/webhook/env-test
NetBox IPAM:         http://localhost:5678/webhook/netbox-ipam
Multi-Tenant Router: http://localhost:5678/webhook/tenant-router
AI Quick Network:    http://localhost:5678/webhook/ai-quick
AI GitOps Complete:  http://localhost:5678/webhook/ai-gitops-automation
```

## 🚨 Troubleshooting

### Common Issues:
1. **404 Webhook Error**: Workflow not activated - toggle "Active" switch
2. **Environment Variables Not Found**: Check docker-compose.yml environment section
3. **NetBox Connection Failed**: Verify NETBOX_TOKEN in credentials
4. **AI Features Not Working**: Validate OPENAI_API_KEY configuration

### Support:
- Check n8n logs: `docker compose logs n8n`
- Validate environment: Run `./test-environment.sh`
- Test individual workflows before using complete pipeline

## 📈 Production Deployment

For production use:
1. Replace `localhost` URLs with actual server addresses
2. Use secure credential management
3. Configure proper SSL certificates
4. Set up monitoring and alerting
5. Implement backup procedures for workflow data

---

**Created**: August 11, 2025  
**Version**: 1.0.0  
**Compatible**: n8n v1.0+, NetBox v3.0+
