# Jenkins CI/CD Pipeline Setup Guide

This setup provides a complete Jenkins-based CI/CD pipeline for NetBox and n8n automation, running entirely in Docker containers.

## Quick Start

### 1. Setup Environment

```bash
# Navigate to the gitlab-cicd directory
cd gitlab-cicd

# Copy and edit the Jenkins environment file
cp .env.jenkins .env
nano .env
```

**Required Configuration:**
```bash
JENKINS_ADMIN_PASSWORD=your_secure_password
NETBOX_TOKEN=your_netbox_api_token
N8N_API_KEY=your_n8n_api_key  # Optional if n8n doesn't require auth
```

### 2. Start the Complete Stack

```bash
# Start Jenkins with NetBox and n8n
docker-compose -f docker-compose.jenkins.yml up -d
```

This will start:
- **Jenkins** at http://localhost:8080
- **NetBox** at http://localhost:8000  
- **n8n** at http://localhost:5678

### 3. Access Jenkins

1. Go to http://localhost:8080
2. Login with:
   - Username: `admin`
   - Password: `your_secure_password` (from .env file)

### 4. Pipeline Jobs

Jenkins comes pre-configured with:

#### Main Pipeline: `poc2-automation`
- **Trigger**: Git webhook or manual
- **Stages**: Health Check → Test → Build → Deploy → Verify
- **Parameters**:
  - `DEPLOYMENT_TYPE`: full, netbox-only, n8n-only, health-check
  - `SKIP_TESTS`: Skip test execution
  - `CREATE_BACKUP`: Create backup before deployment

#### Health Check Jobs:
- `netbox-health-check`: Runs every 15 minutes
- `n8n-health-check`: Runs every 15 minutes

## Pipeline Features

### 🎯 Deployment Types

**Full Deployment** (`full`)
- Complete NetBox configuration deployment
- n8n workflow deployment  
- Cross-system synchronization
- Full integration testing

**NetBox Only** (`netbox-only`)
- Deploy only NetBox configurations
- Skip n8n operations
- NetBox-specific testing

**n8n Only** (`n8n-only`)
- Deploy only n8n workflows
- Skip NetBox operations  
- n8n-specific testing

**Health Check** (`health-check`)
- API connectivity tests only
- No deployments
- Quick status verification

### 🔒 Security & Approvals

**Development**: Automatic deployment
**Staging**: Manual trigger required
**Production**: Manual approval required with timeout

### 📊 Monitoring & Notifications

- **Email notifications** for all build results
- **Slack integration** (optional)
- **HTML reports** for deployment details
- **Artifact archiving** for builds and backups
- **Health check monitoring** every 15 minutes

## Container Architecture

### Jenkins Container Includes:
- **Jenkins LTS** with Configuration as Code
- **Docker CLI** for container operations
- **Python 3** with NetBox/n8n libraries
- **Node.js** for n8n workflow processing
- **Ansible** for infrastructure automation
- **Terraform** for infrastructure as code
- **kubectl & Helm** for Kubernetes deployments
- **Database clients** (PostgreSQL, Redis, MySQL)
- **Network tools** (dig, netcat, etc.)

### Pre-installed Plugins:
- Blue Ocean UI
- Pipeline & Git integration
- Docker workflow
- Credentials management
- Test result publishing
- Email & Slack notifications
- Configuration as Code

## Usage Examples

### Manual Pipeline Execution

1. **Go to Jenkins** → `poc2-automation` → `main` branch
2. **Click "Build with Parameters"**
3. **Select options**:
   - Deployment Type: `full`
   - Skip Tests: `false` 
   - Create Backup: `true`
4. **Click "Build"**

### Health Check Execution

1. **Go to Jenkins** → `netbox-health-check`
2. **Click "Build Now"**
3. **View results** in console output

### Git Integration

The pipeline automatically triggers on:
- **Push to main branch** → Production deployment (with approval)
- **Push to staging branch** → Staging deployment
- **Push to other branches** → Development deployment

## Environment Configuration

### Development Environment
```bash
ENVIRONMENT=development
NETBOX_URL=http://netbox:8000
N8N_URL=http://n8n:5678
```

### Production Environment
```bash
ENVIRONMENT=production
NETBOX_URL=http://netbox-prod:8000
N8N_URL=http://n8n-prod:5678
```

## Maintenance

### View Logs
```bash
# Jenkins logs
docker logs -f poc2-jenkins

# All services
docker-compose -f docker-compose.jenkins.yml logs -f
```

### Update Configuration
```bash
# Edit environment
nano .env

# Restart Jenkins to reload config
docker-compose -f docker-compose.jenkins.yml restart jenkins
```

### Backup Jenkins Configuration
```bash
# Backup Jenkins home directory
docker exec poc2-jenkins tar czf /tmp/jenkins-backup.tar.gz /var/jenkins_home
docker cp poc2-jenkins:/tmp/jenkins-backup.tar.gz ./jenkins-backup.tar.gz
```

## Troubleshooting

### Common Issues

**Jenkins won't start**
```bash
# Check logs
docker logs poc2-jenkins

# Check permissions
docker exec poc2-jenkins ls -la /var/jenkins_home
```

**Pipeline fails with "NetBox not accessible"**
```bash
# Test connectivity
docker exec poc2-jenkins curl -I http://netbox:8000

# Check environment variables
docker exec poc2-jenkins env | grep NETBOX
```

**Docker socket permission denied**
```bash
# Fix Docker socket permissions
sudo chmod 666 /var/run/docker.sock
```

### Debug Mode

Enable debug logging in pipeline:
```groovy
environment {
    DEBUG = 'true'
    LOG_LEVEL = 'DEBUG'
}
```

## Scaling & Production

### For Production Use:

1. **Use external databases** instead of containers
2. **Set up SSL/TLS** with reverse proxy
3. **Configure backup strategies** for Jenkins data
4. **Set up monitoring** with Prometheus/Grafana
5. **Use secrets management** (HashiCorp Vault, etc.)

### High Availability:
- Use Jenkins master/agent setup
- External persistent storage
- Load balancer for web access
- Database clustering

---

**Benefits over GitLab CI/CD:**
- ✅ Simpler setup and configuration
- ✅ Better UI and pipeline visualization  
- ✅ More extensive plugin ecosystem
- ✅ Easier local development and testing
- ✅ No external GitLab instance required
- ✅ Complete self-contained solution
