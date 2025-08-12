# Environment Configuration Guide

This guide helps you set up and manage environment configurations for the GitLab CI/CD pipeline with NetBox and n8n integration.

## Quick Setup

### 1. Initialize Your Local Environment

```bash
# Navigate to the gitlab-cicd directory
cd gitlab-cicd

# Initialize local environment configuration
./scripts/env-manager.sh init local

# Edit the configuration file with your actual values
nano .env.local
```

### 2. Set Your API Tokens

You need to obtain API tokens from your NetBox and n8n instances:

#### NetBox API Token
1. Log into your NetBox instance (http://localhost:8000)
2. Go to: **Admin** → **API Tokens** → **+ Add**
3. Create a token with appropriate permissions
4. Copy the token to your `.env.local` file

#### n8n API Key
1. Log into your n8n instance (http://localhost:5678)
2. Go to: **Settings** → **API Keys** → **Create API Key**
3. Copy the key to your `.env.local` file

### 3. Validate Your Configuration

```bash
# Validate your environment setup
./scripts/env-manager.sh validate local

# Test connectivity to your services
./scripts/env-manager.sh test local
```

## Environment Files

### Available Environments

- **`.env.local`** - Local development environment
- **`.env.development`** - Development/testing environment  
- **`.env.staging`** - Staging environment
- **`.env.production`** - Production environment
- **`.env.example`** - Template with all available options

### Key Variables

#### Required Variables
```bash
# NetBox Configuration
NETBOX_URL=http://localhost:8000          # Your NetBox URL
NETBOX_TOKEN=your_api_token_here          # NetBox API token

# n8n Configuration  
N8N_URL=http://localhost:5678             # Your n8n URL
N8N_API_KEY=your_api_key_here             # n8n API key

# Environment
ENVIRONMENT=local                         # Environment name
```

#### Database Configuration
```bash
DATABASE_URL=postgresql://netbox:password@localhost:5432/netbox
REDIS_URL=redis://localhost:6379/0
```

#### Security Settings
```bash
SECRET_KEY=generate_secure_key_here       # For encryption
ALLOWED_HOSTS=localhost,127.0.0.1         # Comma-separated hosts
```

## Environment Manager Commands

### Basic Commands

```bash
# Show help
./scripts/env-manager.sh help

# Initialize environment
./scripts/env-manager.sh init [environment]

# Validate configuration
./scripts/env-manager.sh validate [environment]

# Show environment (sensitive values masked)
./scripts/env-manager.sh show [environment]

# Test API connectivity
./scripts/env-manager.sh test [environment]
```

### Advanced Commands

```bash
# Copy configuration between environments
./scripts/env-manager.sh copy development staging

# Generate secure tokens
./scripts/env-manager.sh generate-tokens
```

## Security Best Practices

### 1. Environment File Security
- **Never commit `.env` files to git** (they're in `.gitignore`)
- Use different tokens for each environment
- Rotate tokens regularly
- Use strong, unique passwords

### 2. Token Management
```bash
# Generate secure tokens
./scripts/env-manager.sh generate-tokens

# Example output:
NETBOX_TOKEN=a1b2c3d4e5f6789012345678901234567890abcd
N8N_API_KEY=9876543210fedcba0987654321abcdef12345678
SECRET_KEY=super_long_secret_key_for_encryption_purposes
GITLAB_TOKEN=gitlab_runner_registration_token_here
```

### 3. GitLab CI/CD Variables
For GitLab pipelines, set these as **protected variables**:

- `NETBOX_TOKEN_DEV` - Development NetBox token
- `NETBOX_TOKEN_STAGING` - Staging NetBox token  
- `NETBOX_TOKEN_PROD` - Production NetBox token
- `N8N_API_KEY_DEV` - Development n8n key
- `N8N_API_KEY_STAGING` - Staging n8n key
- `N8N_API_KEY_PROD` - Production n8n key

## Common Issues and Solutions

### Issue: "Missing required variable"
**Solution:** Make sure all required variables are set in your environment file.
```bash
./scripts/env-manager.sh validate local
```

### Issue: "API not accessible"
**Solution:** Check your URLs and tokens:
```bash
# Test individual components
curl -H "Authorization: Token YOUR_TOKEN" http://localhost:8000/api/status/
curl -H "X-N8N-API-KEY: YOUR_KEY" http://localhost:5678/api/v1/workflows
```

### Issue: "Environment file not found"
**Solution:** Initialize the environment:
```bash
./scripts/env-manager.sh init local
```

### Issue: "Permission denied" when running scripts
**Solution:** Make scripts executable:
```bash
chmod +x scripts/*.sh
```

## Environment-Specific Setup

### Local Development
```bash
# For your current NetBox/n8n setup
NETBOX_URL=http://localhost:8000
N8N_URL=http://localhost:5678
ENVIRONMENT=local
DEBUG=true
```

### Docker Compose Integration
If you're using Docker Compose, create a `.env` file in the compose directory:
```bash
# Copy your local configuration
cp gitlab-cicd/.env.local docker-compose/.env

# Or link them
ln -s ../gitlab-cicd/.env.local docker-compose/.env
```

### Production Deployment
```bash
# Use secure, production-ready settings
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=WARNING
SKIP_SSL_VERIFY=false
MONITORING_ENABLED=true
BACKUP_ENABLED=true
```

## Testing Your Setup

### 1. Environment Validation
```bash
# Validate all environments
for env in local development staging production; do
    echo "Testing $env environment:"
    ./scripts/env-manager.sh validate $env
    echo "---"
done
```

### 2. API Connectivity
```bash
# Test local environment
./scripts/env-manager.sh test local

# Test with actual pipeline scripts
cd gitlab-cicd
./scripts/netbox-integration.sh test
./scripts/n8n-integration.sh test
```

### 3. Full Pipeline Test
```bash
# Run a complete pipeline test
./scripts/pipeline-orchestrator.sh health
```

## Troubleshooting

### Debug Mode
Enable debug logging for troubleshooting:
```bash
export DEBUG=1
export LOG_LEVEL=DEBUG
./scripts/pipeline-orchestrator.sh test
```

### Log Files
Check logs for detailed error information:
- Pipeline logs: `logs/pipeline_*.log`
- Error reports: `reports/error_report.json`
- Individual script logs in terminal output

### Support
For issues:
1. Check the logs first
2. Validate your environment configuration
3. Test API connectivity manually
4. Check the GitLab CI/CD documentation

---

**Remember**: Keep your API tokens secure and never share them in plain text!
