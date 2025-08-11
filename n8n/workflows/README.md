# NetBox API Integration with n8n

## Overview
This guide helps you integrate n8n with NetBox for network automation, device management, and compliance monitoring.

## Prerequisites
- NetBox running on `http://localhost:8000`
- n8n running on `http://localhost:5678`
- NetBox API token configured

## Quick Setup

### 1. Create NetBox API Token
```bash
# Access NetBox container and create superuser if not already done
cd /home/dan/POC2/netbox-docker
docker compose exec netbox /opt/netbox/netbox/manage.py createsuperuser

# Access NetBox web interface at http://localhost:8000
# Login and go to: Admin → Users → Tokens → Add Token
# Copy the token for n8n configuration
```

### 2. Configure n8n Credentials
1. Open n8n at `http://localhost:5678`
2. Go to Settings → Credentials
3. Create new credential:
   - **Name**: `netbox`
   - **Type**: HTTP Header Auth
   - **Header Name**: `Authorization`
   - **Header Value**: `Token YOUR_NETBOX_TOKEN_HERE`

### 3. Import Workflows
Import the following workflow files into n8n:
- `netbox-device-discovery.json` - Automated device discovery and reporting
- `netbox-ipam-management.json` - IP address management via webhook
- `netbox-compliance-check.json` - Network compliance monitoring

## Available Workflows

### 1. NetBox Device Discovery
**Purpose**: Automatically discovers and reports on NetBox devices every 15 minutes
**Features**:
- Retrieves all devices from NetBox
- Gets interface information for each device
- Generates comprehensive device reports
- Tracks device status, location, and IP assignments

**Manual Trigger**: Click "Execute Workflow" in n8n
**Automatic**: Runs every 15 minutes

### 2. NetBox IPAM Management
**Purpose**: REST API endpoint for IP address management
**Webhook URL**: `http://localhost:5678/webhook/netbox-ipam`

**Example Usage**:
```bash
# Create new IP address
curl -X POST http://localhost:5678/webhook/netbox-ipam \
  -H "Content-Type: application/json" \
  -d '{
    "action": "create_ip",
    "ip_address": "192.168.1.100/24",
    "description": "Server IP",
    "dns_name": "server01.local",
    "device_name": "switch01"
  }'
```

**Response**:
```json
{
  "success": true,
  "ip_address": "192.168.1.100/24",
  "id": 123,
  "status": "active",
  "description": "Server IP",
  "assigned_device": "switch01",
  "created_at": "2025-08-11T12:00:00Z",
  "netbox_url": "http://localhost:8000/ipam/ip-addresses/123/"
}
```

### 3. NetBox Compliance Check
**Purpose**: Monitors network compliance and generates reports every 6 hours
**Compliance Checks**:
- Devices without primary IP addresses
- Missing device descriptions
- Unassigned rack locations
- Unassigned site locations

**Features**:
- Calculates compliance scores
- Categorizes issues by severity (High/Medium/Low)
- Generates detailed markdown reports
- Tracks compliance trends over time

## API Endpoints Reference

### Common NetBox API Calls

```javascript
// Get all devices
GET http://localhost:8000/api/dcim/devices/
Headers: Authorization: Token YOUR_TOKEN

// Get device by name
GET http://localhost:8000/api/dcim/devices/?name=device-name
Headers: Authorization: Token YOUR_TOKEN

// Get device interfaces
GET http://localhost:8000/api/dcim/interfaces/?device_id=123
Headers: Authorization: Token YOUR_TOKEN

// Create IP address
POST http://localhost:8000/api/ipam/ip-addresses/
Headers: Authorization: Token YOUR_TOKEN
Body: {
  "address": "192.168.1.100/24",
  "status": "active",
  "description": "Server IP"
}

// Get IP prefixes
GET http://localhost:8000/api/ipam/prefixes/
Headers: Authorization: Token YOUR_TOKEN

// Get sites
GET http://localhost:8000/api/dcim/sites/
Headers: Authorization: Token YOUR_TOKEN
```

## Advanced Configuration

### Environment Variables for Docker
Add to your n8n environment:
```env
NETBOX_URL=http://host.docker.internal:8000
NETBOX_TOKEN=your_token_here
```

### Webhook Security
For production, secure your webhooks:
1. Use HTTPS
2. Implement webhook authentication
3. Validate request origins
4. Rate limit requests

### Custom Workflows
Create custom workflows for:
- Cable management tracking
- Circuit provisioning
- Device lifecycle management
- Network topology mapping
- Configuration compliance
- Capacity planning

## Troubleshooting

### Common Issues

1. **Connection Refused**
   - Ensure NetBox is accessible at `http://host.docker.internal:8000`
   - Check Docker network connectivity
   - Verify NetBox container is healthy

2. **Authentication Failed**
   - Verify API token is correct
   - Check token permissions in NetBox
   - Ensure Authorization header format: `Token YOUR_TOKEN`

3. **Workflow Execution Errors**
   - Check n8n logs: `docker logs n8n-network-automation`
   - Verify NetBox API responses
   - Test API calls manually with curl

### Logs and Monitoring
```bash
# Check n8n logs
docker logs -f n8n-network-automation

# Check NetBox logs
cd /home/dan/POC2/netbox-docker
docker compose logs -f netbox

# Monitor workflow executions in n8n web interface
# Go to: Executions tab in n8n
```

## Best Practices

1. **Error Handling**: Always include error handling nodes in workflows
2. **Rate Limiting**: Don't overwhelm NetBox API with too many requests
3. **Data Validation**: Validate input data before API calls
4. **Logging**: Use n8n's built-in logging for debugging
5. **Testing**: Test workflows in development before production
6. **Backup**: Export and backup your n8n workflows regularly

## Integration Examples

### Ansible Integration
Combine with Ansible for device configuration:
```yaml
# ansible/netbox-sync.yml
- name: Get devices from NetBox
  uri:
    url: "http://localhost:8000/api/dcim/devices/"
    headers:
      Authorization: "Token {{ netbox_token }}"
  register: netbox_devices

- name: Configure devices
  ios_config:
    lines:
      - "hostname {{ item.name }}"
    provider: "{{ cli }}"
  loop: "{{ netbox_devices.json.results }}"
```

### Monitoring Integration
Send compliance reports to monitoring systems:
- Prometheus metrics
- Grafana dashboards  
- Slack notifications
- Email alerts

## Support and Documentation

- n8n Documentation: https://docs.n8n.io/
- NetBox API Documentation: http://localhost:8000/api/docs/
- NetBox Community: https://github.com/netbox-community/netbox
- This project repository: https://github.com/dashton956-alt/POC2

## Next Steps

1. Import the provided workflows into n8n
2. Configure NetBox API credentials
3. Test each workflow manually
4. Customize workflows for your environment
5. Set up monitoring and alerting
6. Integrate with your existing automation tools
