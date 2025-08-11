# n8n Network Automation Project

This directory contains n8n setup and AI-powered GitOps network automation components.

## 📁 Project Structure

```
n8n/
├── README.md                     # This overview
├── setup-ai-gitops.sh          # Quick setup script
├── Dockerfile                   # n8n container with network tools
├── docker-compose.yml          # Complete n8n deployment
└── ai-gitops/                  # 🤖 AI GitOps Automation Suite
    ├── README.md               # Detailed AI GitOps documentation
    ├── workflows/              # n8n workflow configurations
    │   ├── n8n_ai_gitops_workflow_implementation.md
    │   ├── ai_gitops_workflow_nodes.js
    │   └── set_node_config.json
    ├── templates/              # Ansible playbook templates
    │   └── ansible_playbook_templates.md
    ├── docs/                   # Comprehensive documentation
    │   ├── deployment_guide.md
    │   ├── ai_gitops_network_automation.md
    │   ├── intent_based_network_workflow_diagram.md
    │   └── set_node_guide.md
    ├── scripts/                # Utility scripts
    │   ├── TFS_Number.py
    │   ├── validation_code_node.js
    │   └── simple_validation_function.js
    └── ci-cd/                 # CI/CD pipeline configurations
        └── gitlab-ci.yml
```

## 🚀 Quick Start

### Option 1: Automated Setup
```bash
# Run the setup script
./setup-ai-gitops.sh
```

### Option 2: Manual Setup
```bash
# Deploy n8n
docker-compose up -d

# Access n8n at http://localhost:5678
# Follow ai-gitops/README.md for configuration
```

## 🤖 AI GitOps Features

- **AI Intent Processing**: Natural language → network configurations
- **NetBox Integration**: Dynamic inventory and data enrichment
- **Auto Playbook Generation**: AI creates Ansible playbooks
- **GitOps Workflow**: Version control and automated deployment
- **Enterprise Integrations**: ServiceNow, GitLab, notifications
- **Full Audit Trail**: Complete change tracking and compliance

## 📚 Documentation

| File | Purpose |
|------|---------|
| `ai-gitops/README.md` | Main AI GitOps documentation |
| `ai-gitops/docs/deployment_guide.md` | Complete implementation guide |
| `ai-gitops/docs/ai_gitops_network_automation.md` | Architecture overview |
| `ai-gitops/workflows/` | n8n workflow configurations |
| `ai-gitops/templates/` | Ansible playbook templates |

## ⚙️ Environment Configuration

Set these variables in n8n (Settings > Environments):
- `OPENAI_API_KEY` - AI service integration
- `NETBOX_URL` / `NETBOX_TOKEN` - Network inventory
- `GITLAB_URL` / `GITLAB_TOKEN` - GitOps integration
- `SERVICENOW_URL` / `SERVICENOW_AUTH` - Change management

## 🔧 Container Management

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f n8n

# Stop services  
docker-compose down

# Rebuild after changes
docker-compose build --no-cache
docker-compose up -d
```

## 📊 Project Status

✅ **n8n Base Setup** - Container, volumes, networking  
✅ **AI GitOps Framework** - Complete workflow implementation  
✅ **Documentation** - Comprehensive guides and examples  
✅ **Templates** - Ansible playbook generation templates  
✅ **CI/CD Pipeline** - GitLab automation configuration  
✅ **Deployment Guide** - 10-phase implementation roadmap  

## 🎯 Next Steps

1. **Deploy**: Run `./setup-ai-gitops.sh`
2. **Configure**: Set environment variables in n8n
3. **Import**: Load workflows from `ai-gitops/workflows/`
4. **Test**: Start with simple network changes
5. **Scale**: Implement full enterprise integrations

---

**For detailed information, see `ai-gitops/README.md`**
