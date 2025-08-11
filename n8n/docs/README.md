# n8n AI GitOps Network Automation Platform

Enterprise-grade network automation platform combining n8n workflows, AI-powered intent processing, GitLab CI/CD pipelines, and comprehensive monitoring.

## 📁 Project Structure

```
n8n/
├── README.md                     # This overview  
├── setup-ai-gitops.sh          # 🚀 One-command deployment script
├── test-pipeline.sh             # 🧪 Pipeline testing utility
├── register-gitlab-runner.sh    # 🔧 GitLab Runner setup
├── docker-compose.yml          # Complete stack deployment
├── Dockerfile                   # n8n container with network tools
├── Dockerfile.ansible          # Ansible pipeline executor
├── ansible.cfg                 # Ansible configuration
├── env.example                 # Environment configuration template
├── monitoring/                 # Prometheus & Grafana configs
│   ├── prometheus.yml
│   └── grafana/
└── ai-gitops/                  # 🤖 AI GitOps Automation Suite
    ├── README.md               # Detailed AI GitOps documentation
    ├── workflows/              # n8n workflow configurations  
    ├── templates/              # Ansible playbook templates
    ├── docs/                   # Comprehensive documentation
    ├── scripts/                # Utility scripts
    └── ci-cd/                 # CI/CD pipeline configurations
```

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)
```bash
# Clone and deploy the complete stack
git clone https://github.com/dashton956-alt/POC2.git
cd POC2/n8n

# Configure environment (copy and customize)
cp env.example .env
# Edit .env with your specific values

# Deploy everything with one command
./setup-ai-gitops.sh
```

### Option 2: Manual Step-by-Step
```bash
# Deploy core services
docker-compose up -d

# Register GitLab Runner (after setting environment variables)
export GITLAB_URL=https://gitlab.your-company.com
export GITLAB_REGISTRATION_TOKEN=your-token
./register-gitlab-runner.sh

# Test the pipeline
./test-pipeline.sh
```

## 🏗️ Architecture Components

### **Core Services**
- **n8n** (`:5678`) - Workflow automation with AI integration
- **PostgreSQL** - Persistent data storage
- **Redis** - Caching and queue management

### **CI/CD Pipeline**
- **GitLab Runner** - Pipeline execution engine
- **Ansible Executor** - Network automation container
- **Pipeline Monitoring** - Execution tracking and alerts

### **Monitoring Stack**
- **Prometheus** (`:9090`) - Metrics collection
- **Grafana** (`:3000`) - Dashboards and visualization

### **AI GitOps Features**
- **AI Intent Processing** - Natural language → network configurations
- **NetBox Integration** - Dynamic inventory and data enrichment
- **Auto Playbook Generation** - AI creates Ansible playbooks
- **GitOps Workflow** - Version control and automated deployment
- **Enterprise Integrations** - ServiceNow, notifications, approvals

## 📊 Service Access

| Service | URL | Default Login | Purpose |
|---------|-----|---------------|---------|
| n8n | http://localhost:5678 | admin/secure_password_change_me | Workflow automation |
| Grafana | http://localhost:3000 | admin/admin_change_me | Monitoring dashboards |
| Prometheus | http://localhost:9090 | N/A | Metrics and alerting |

## ⚙️ Configuration

### 1. Environment Variables
Copy `env.example` to `.env` and configure:
- **AI Integration**: OpenAI API keys, models, settings
- **NetBox**: URL, API token, version
- **GitLab**: URL, tokens, project ID, runner registration
- **ServiceNow**: Instance URL, credentials
- **Network Devices**: SSH credentials, connection settings
- **Notifications**: Slack, Teams, email, PagerDuty
- **Security**: Vault passwords, SSL certificates

### 2. GitLab CI/CD Setup
```bash
# Set your GitLab details
export GITLAB_URL=https://gitlab.your-company.com
export GITLAB_REGISTRATION_TOKEN=your-project-runner-token

# Register the runner
./register-gitlab-runner.sh

# Copy the CI/CD pipeline to your repository
cp ai-gitops/ci-cd/gitlab-ci.yml your-repo/.gitlab-ci.yml
```

### 3. Network Device Access
- Configure SSH keys in `~/.ssh/` (mounted to containers)
- Set network credentials in `.env` file
- Test connectivity with the pipeline tester

## 🔧 Management Commands

### **Stack Management**
```bash
# Deploy/update services
docker-compose up -d

# View all service status
docker-compose ps

# View logs (all services or specific)
docker-compose logs -f [service-name]

# Restart specific service
docker-compose restart [service-name]

# Stop all services
docker-compose down
```

### **GitLab Pipeline Management**
```bash
# Register/re-register runner
./register-gitlab-runner.sh

# Test pipeline functionality
./test-pipeline.sh

# View runner status
docker exec gitlab-runner-network-automation gitlab-runner status

# View runner logs
docker logs gitlab-runner-network-automation
```

### **Ansible Operations**
```bash
# Access Ansible container
docker exec -it ansible-pipeline-executor bash

# Test Ansible installation
docker exec ansible-pipeline-executor ansible --version

# Test network collections
docker exec ansible-pipeline-executor ansible-galaxy collection list

# Run test playbook
docker exec ansible-pipeline-executor ansible-playbook /opt/test-playbook.yml
```

## 🧪 Testing & Validation

### **Pipeline Testing**
```bash
# Run comprehensive pipeline tests
./test-pipeline.sh

# Test individual components
docker exec ansible-pipeline-executor ansible --version
docker exec gitlab-runner-network-automation gitlab-runner status
curl http://localhost:5678/health
curl http://localhost:9090/metrics
```

### **Network Connectivity Testing**
```bash
# Test from Ansible container
docker exec ansible-pipeline-executor ping your-network-device
docker exec ansible-pipeline-executor ssh -o ConnectTimeout=5 user@device "show version"
```

## 🚨 Troubleshooting

### **Common Issues**

1. **Services Won't Start**
   ```bash
   # Check logs
   docker-compose logs [service-name]
   
   # Check system resources
   docker system df
   docker system prune -f
   ```

2. **GitLab Runner Registration Failed**
   ```bash
   # Check GitLab connectivity
   curl -k $GITLAB_URL
   
   # Verify registration token
   # Get from: Project Settings > CI/CD > Runners
   ```

3. **n8n Workflow Failures**
   ```bash
   # Check n8n logs
   docker-compose logs n8n
   
   # Access n8n container
   docker exec -it n8n-network-automation bash
   ```

4. **Network Device Access Issues**
   ```bash
   # Test from Ansible container
   docker exec ansible-pipeline-executor ssh -vvv user@device
   
   # Check SSH key permissions
   docker exec ansible-pipeline-executor ls -la /root/.ssh/
   ```

### **Log Locations**
- n8n logs: `docker-compose logs n8n`
- Pipeline logs: `docker exec ansible-pipeline-executor ls /opt/logs/`
- GitLab Runner: `docker logs gitlab-runner-network-automation`
- Ansible execution: Inside pipeline containers during runs

## 📈 Monitoring & Metrics

### **Key Metrics Available**
- Workflow execution time and success rate
- AI API usage and response times
- GitLab pipeline success/failure rates
- Network device connectivity status
- System resource utilization
- Security scan results

### **Grafana Dashboards**
Access Grafana at `http://localhost:3000` for:
- n8n workflow performance
- GitLab CI/CD pipeline metrics
- Infrastructure monitoring
- Network automation KPIs
- Alert management

## 🔒 Security Considerations

### **Secrets Management**
- Use `.env` file for sensitive configuration
- Store SSH keys securely with proper permissions
- Rotate API tokens and passwords regularly
- Use Ansible Vault for encrypted data

### **Network Security**
- Secure n8n with proper authentication
- Use SSL/TLS for external connections
- Implement network segregation
- Regular security scans in CI/CD pipeline

### **Access Control**
- GitLab project access controls
- n8n workflow permissions
- Network device privilege escalation
- Audit trail for all changes

## 🎯 Production Deployment

### **Pre-Production Checklist**
- [ ] SSL certificates configured
- [ ] Production credentials set
- [ ] Monitoring and alerting configured
- [ ] Backup procedures tested
- [ ] Disaster recovery plan documented
- [ ] Security scan passed
- [ ] Performance testing completed

### **Scaling Considerations**
- Multiple GitLab Runner instances
- Database connection pooling
- Redis clustering for high availability
- Load balancing for n8n instances
- Horizontal scaling of monitoring

## 📚 Documentation

### **Getting Started**
- [AI GitOps README](ai-gitops/README.md) - Main documentation
- [Deployment Guide](ai-gitops/docs/deployment_guide.md) - Step-by-step setup
- [Architecture Overview](ai-gitops/docs/ai_gitops_network_automation.md)

### **Implementation**
- [n8n Workflows](ai-gitops/workflows/) - Workflow configurations
- [Ansible Templates](ai-gitops/templates/) - Playbook templates  
- [CI/CD Pipeline](ai-gitops/ci-cd/) - GitLab configuration

### **Operations**
- Environment configuration: `env.example`
- Pipeline testing: `test-pipeline.sh`
- GitLab setup: `register-gitlab-runner.sh`

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-capability`
3. Test thoroughly with `./test-pipeline.sh`
4. Submit pull request with detailed description
5. Ensure CI/CD pipeline passes

## 📞 Support

- **Issues**: Create GitHub issue with detailed description
- **Documentation**: Check `ai-gitops/docs/` folder
- **Testing**: Use `./test-pipeline.sh` for diagnostics
- **Logs**: Use `docker-compose logs [service]` for troubleshooting

---

**🎯 Ready to deploy enterprise-grade AI-powered network automation with full CI/CD pipeline integration!**
