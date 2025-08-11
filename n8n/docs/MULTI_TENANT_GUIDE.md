# Multi-Tenant n8n Configuration Guide

## Overview
n8n can be configured for multiple customers/tenants using several approaches:

### 1. Environment Variable Templates
Use environment variables to customize workflows per tenant without rebuilding.

### 2. Database-Driven Configuration  
Store customer-specific configurations in a database that workflows can query.

### 3. Webhook-Based Customer Routing
Route requests to appropriate customer contexts based on headers/parameters.

### 4. Credential Management per Tenant
Separate credential sets for each customer's integrations.

## Implementation Examples

### Template Workflow with Customer Variables
```javascript
// In n8n workflows, use expressions like:
const customerConfig = {
  netboxUrl: $env.CUSTOMER_NETBOX_URL || 'http://default-netbox:8000',
  apiToken: $credentials.netbox_token,
  customerId: $json.headers['x-customer-id'] || $env.DEFAULT_CUSTOMER_ID,
  webhookPrefix: $env.CUSTOMER_WEBHOOK_PREFIX || 'default'
};
```

### Customer Configuration Database
```sql
CREATE TABLE customer_configs (
  customer_id VARCHAR(50) PRIMARY KEY,
  netbox_url VARCHAR(255),
  api_token_ref VARCHAR(100),
  webhook_prefix VARCHAR(50),
  config_json TEXT
);
```

### Multi-Tenant Workflow Structure
```
/workflows/
  ├── templates/           # Base workflow templates
  │   ├── netbox-discovery-template.json
  │   ├── ipam-management-template.json
  │   └── compliance-check-template.json
  ├── customers/           # Customer-specific instances
  │   ├── customer-a/
  │   ├── customer-b/
  │   └── customer-c/
  └── shared/              # Common utilities
      └── customer-router.json
```

## Benefits
- ✅ Single workflow maintenance
- ✅ Rapid customer onboarding  
- ✅ Centralized configuration management
- ✅ Isolated customer data and credentials
- ✅ Scalable architecture
