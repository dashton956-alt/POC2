# AI GitOps Network Automation

This folder contains all the components for AI-powered GitOps network automation using n8n, including AI intent processing, NetBox integration, automated Ansible playbook generation, and complete CI/CD pipeline orchestration.

## 📁 Folder Structure

```
ai-gitops/
├── README.md                           # This file - project overview
├── workflows/                          # n8n workflow configurations
│   ├── n8n_ai_gitops_workflow_implementation.md
│   ├── ai_gitops_workflow_nodes.js
│   └── set_node_config.json
├── templates/                          # Ansible playbook templates
│   └── ansible_playbook_templates.md
├── docs/                              # Documentation
│   ├── deployment_guide.md
│   ├── ai_gitops_network_automation.md
│   ├── intent_based_network_workflow_diagram.md
│   └── set_node_guide.md
├── scripts/                           # Utility scripts
│   ├── TFS_Number.py
│   ├── validation_code_node.js
│   └── simple_validation_function.js
└── ci-cd/                            # CI/CD pipeline configurations
    └── gitlab-ci.yml
```

## 🚀 Quick Start

### 1. Deploy n8n Container
```bash
# From /home/dan/POC2/n8n directory
docker-compose up -d
```

### 2. Access n8n Interface
- URL: http://localhost:5678
- Default credentials: Check docker-compose.yml

### 3. Import AI GitOps Workflow
1. Navigate to workflows/n8n_ai_gitops_workflow_implementation.md
2. Follow the node configurations to build the complete workflow
3. Configure environment variables for all integrations

## 🧠 AI GitOps Architecture

### Core Components:
- **AI Intent Processor**: Converts natural language to structured network configs
- **NetBox Integration**: Dynamic inventory and data enrichment
- **AI Playbook Generator**: Creates Ansible playbooks automatically
- **GitOps Pipeline**: Version control, approvals, and automated deployment
- **Enterprise Integrations**: ServiceNow, GitLab, Slack/Teams notifications

### Workflow Flow:
```
Natural Language Input → AI Processing → NetBox Data → AI Playbook Generation → 
Git Commit → Approvals → CI/CD Pipeline → Production Deployment → Audit Trail
```

## 📋 Key Features

✅ **AI-Powered Intent Processing** - Natural language → structured configs  
✅ **NetBox Integration** - Dynamic inventory and dependency mapping  
✅ **Auto-Generated Playbooks** - AI creates production-ready Ansible code  
✅ **GitOps Workflow** - Infrastructure as code with version control  
✅ **Multi-Layer Approvals** - Code review + Change management integration  
✅ **Automated CI/CD** - Staging → Production deployment pipeline  
✅ **Enterprise Security** - Backup, validation, rollback, and audit trails  
✅ **Full Observability** - Logging, monitoring, and alerting integration  

## 🔧 Configuration Requirements

### Environment Variables (n8n)
```bash
# AI Integration
OPENAI_API_KEY=your-openai-api-key

# NetBox Integration  
NETBOX_URL=https://your-netbox-instance.com
NETBOX_TOKEN=your-netbox-api-token

# GitLab Integration
GITLAB_URL=https://gitlab.your-company.com
GITLAB_TOKEN=your-gitlab-api-token
PROJECT_ID=123

# ServiceNow Integration
SERVICENOW_URL=https://your-instance.service-now.com
SERVICENOW_AUTH=base64(username:password)

# Team Configuration
NETWORK_TEAM_LEAD_ID=123
SENIOR_NETWORK_ENGINEER_ID=456
SECURITY_REVIEWER_ID=789

# Notifications
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
TEAMS_WEBHOOK_URL=https://company.webhook.office.com/...
```

### External Dependencies
- NetBox instance (network inventory)
- GitLab instance with CI/CD runners
- ServiceNow instance (change management)
- OpenAI API access
- Network devices with SSH/API access
- Ansible control node

## 📚 Documentation Guide

### Getting Started
1. **deployment_guide.md** - Complete 10-phase implementation guide
2. **set_node_guide.md** - n8n node configuration basics
3. **ai_gitops_network_automation.md** - Architecture overview

### Implementation
1. **workflows/** - n8n workflow node configurations
2. **templates/** - Ansible playbook templates for AI generation
3. **ci-cd/** - GitLab CI/CD pipeline configuration

### Scripts & Utilities
- **TFS_Number.py** - Generate unique tracking numbers
- **validation_code_node.js** - Workflow validation functions
- **simple_validation_function.js** - Basic validation utilities

## 🛠️ Development Workflow

### 1. Test Individual Components
```bash
# Test TFS number generation
python scripts/TFS_Number.py

# Test n8n workflow nodes individually
# Import workflow nodes and test with sample data
```

### 2. Integration Testing
```bash
# Test API integrations
curl -H "Authorization: Token your-token" https://your-netbox.com/api/dcim/devices/
curl -H "Authorization: Bearer your-token" https://gitlab.your-company.com/api/v4/projects
```

### 3. End-to-End Testing
```bash
# Test complete workflow with sample network change request
curl -X POST http://n8n.your-company.com:5678/webhook/network-automation \
  -H "Content-Type: application/json" \
  -d '{"user_request": "Create VLAN 100 for Sales team", "priority": "medium"}'
```

## 🚨 Troubleshooting

### Common Issues
1. **n8n Workflow Failures**: Check individual node configurations and API credentials
2. **AI API Rate Limits**: Monitor OpenAI usage and implement retry logic
3. **GitLab Pipeline Failures**: Check CI/CD logs and Ansible playbook syntax
4. **NetBox Connectivity**: Verify API tokens and network access

### Debug Commands
```bash
# Check n8n logs
docker-compose logs -f n8n

# Validate Ansible playbooks
ansible-lint playbooks/generated/site.yml
ansible-playbook --syntax-check playbooks/generated/site.yml

# Test network device connectivity
ansible all -i inventories/staging/hosts.yml -m ping
```

## 📈 Monitoring & Metrics

### Key Metrics
- Workflow execution time
- AI generation success rate
- Deployment success rate
- Change request approval time
- Network automation coverage

### Logging
- n8n workflow execution logs
- GitLab CI/CD pipeline logs
- Ansible playbook execution logs
- Network device configuration changes

## 🔒 Security Considerations

### Secrets Management
- Use n8n credential store for sensitive data
- Rotate API keys and tokens regularly
- Implement least-privilege access

### Network Security
- Secure n8n with SSL/TLS
- Restrict access to trusted networks
- Use SSH keys for device access

### Audit & Compliance
- All changes tracked in Git history
- ServiceNow change request integration
- Complete audit trail from intent to deployment

## 📞 Support & Contact

For issues, questions, or contributions:
1. Check the troubleshooting guide
2. Review the documentation in docs/
3. Test individual components first
4. Create detailed issue reports with logs

---

**Note**: This is a comprehensive enterprise-grade network automation solution. Start with basic components and gradually add complexity as your team becomes comfortable with the platform.
