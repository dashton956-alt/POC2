# Sensitive File Management Guide

This document outlines how sensitive files are handled in the POC2 project to maintain security while ensuring reproducibility.

## Overview

The POC2 project contains multiple services with various configuration files, credentials, and secrets. This guide explains which files contain sensitive information and how they are managed.

## Sensitive Files Excluded from Git

The following sensitive files are excluded from version control via `.gitignore`:

### Environment Files
- `**/.env` - All environment files containing secrets
- `**/env/` - Environment configuration directories
- `**/*.env` (except `.env.example` and `.env.template`)

### Specific Service Files

#### NetBox
- `netbox-docker/env/netbox.env` - Contains SECRET_KEY, DB passwords, Redis passwords
- `netbox-docker/env/postgres.env` - Database credentials
- `netbox-docker/env/redis.env` - Redis passwords
- `netbox-docker/env/redis-cache.env` - Redis cache passwords

#### Diode
- `diode/.env` - OAuth2 secrets, database passwords, system secrets
- `diode/oauth2/client/client-credentials.json` - OAuth2 client secrets

#### n8n
- `n8n/config/credentials/` - Workflow credentials and API keys

#### Jenkins/GitLab CI/CD
- `gitlab-cicd/.env` - CI/CD credentials and tokens

### Database and Runtime Files
- `**/*.db`, `**/*.sqlite*` - Database files
- `**/postgres-data/`, `**/redis-data/` - Persistent data volumes
- `**/volumes/`, `**/data/` - Docker volume mounts
- `**/logs/`, `**/*.log` - Log files that may contain sensitive data

## Template Files (Tracked in Git)

To enable easy setup and configuration, template files are provided:

### Configuration Templates
- `netbox-docker/env/netbox.env.example` - NetBox configuration template
- `netbox-docker/env/postgres.env.example` - PostgreSQL configuration template  
- `diode/.env.example` - Diode service configuration template
- `diode/oauth2/client/client-credentials.json.example` - OAuth2 client template
- `gitlab-cicd/.env.example` - CI/CD configuration template

## Initial Setup Process

1. **Copy Template Files**:
   ```bash
   # NetBox configuration
   cp netbox-docker/env/netbox.env.example netbox-docker/env/netbox.env
   cp netbox-docker/env/postgres.env.example netbox-docker/env/postgres.env
   
   # Diode configuration
   cp diode/.env.example diode/.env
   cp diode/oauth2/client/client-credentials.json.example diode/oauth2/client/client-credentials.json
   
   # GitLab CI/CD configuration
   cp gitlab-cicd/.env.example gitlab-cicd/.env
   ```

2. **Generate Secure Passwords and Secrets**:
   ```bash
   # Generate random passwords (adjust length as needed)
   openssl rand -base64 32  # For database passwords
   openssl rand -base64 64  # For secret keys
   ```

3. **Update Configuration Files**:
   - Replace all `YOUR_*_HERE` placeholders with actual values
   - Ensure passwords are consistent across related services
   - Update URLs and ports to match your environment

## Security Best Practices

### Password Generation
- Use strong, randomly generated passwords
- Use different passwords for different services
- Store passwords securely (password manager recommended)

### Secret Key Generation
- Generate cryptographically secure random keys
- Use appropriate key lengths (32+ bytes for most applications)
- Rotate secrets regularly in production environments

### File Permissions
```bash
# Restrict access to sensitive files
chmod 600 */.env
chmod 600 */env/*.env
chmod 600 */oauth2/client/client-credentials.json
```

### Environment-Specific Configuration
Consider using different configuration sets for:
- Development
- Staging  
- Production

## Troubleshooting

### Missing Configuration Files
If services fail to start due to missing configuration:

1. Check that all required `.env` files exist
2. Verify template files have been copied and populated
3. Ensure file permissions are correct
4. Check Docker Compose logs for specific error messages

### Permission Denied Errors
```bash
# Fix file permissions
sudo chown -R $USER:$USER .
chmod -R 755 .
chmod 600 */.env */env/*.env
```

### Inconsistent Passwords
Ensure the same database passwords are used across all services that connect to the same database:
- NetBox and PostgreSQL must use matching credentials
- Redis services must use consistent passwords
- OAuth2 client secrets must match between services

## Monitoring and Maintenance

### Regular Tasks
- Review and rotate secrets quarterly
- Update template files when new configuration options are added
- Monitor logs for authentication failures
- Backup configuration files securely (encrypted)

### Security Audits
- Regularly check that sensitive files are not accidentally committed
- Verify `.gitignore` patterns catch all sensitive files
- Review file permissions on production systems
- Scan for hardcoded secrets in source code

## Emergency Procedures

### Compromised Secrets
1. Generate new secrets immediately
2. Update all affected configuration files
3. Restart all affected services
4. Review access logs for unauthorized access
5. Update any external integrations using the old secrets

### Lost Configuration
1. Use template files to reconstruct configuration
2. Check backup systems for recent configuration snapshots
3. Document any customizations that need to be recreated
4. Test all services thoroughly after reconstruction
