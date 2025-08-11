# 🔒 n8n Workflow Persistence in Isolated Environments

## ✅ **CONFIRMED: Workflows DO Remain in Separate Environments**

### **How Workflow Persistence Works:**

1. **Database Storage**: All workflows stored in PostgreSQL database
2. **Volume Mounting**: Database persists across container restarts  
3. **Environment Isolation**: Each customer can have completely separate stack
4. **Template Deployment**: Workflows can be deployed programmatically

## 🏗️ **Deployment Models & Workflow Retention:**

### **Model 1: Complete Isolation (Container-Per-Customer)**
```bash
# Customer A Environment
/customer-a/
├── docker-compose.yml (n8n + postgres + redis)
├── workflows/ (imported once, persist forever)
└── data/ (isolated customer data)

# Customer B Environment  
/customer-b/
├── docker-compose.yml (n8n + postgres + redis)
├── workflows/ (same templates, different data)
└── data/ (isolated customer data)
```

**Workflow Status**: ✅ **PERSISTENT** - Each environment has own database

### **Model 2: Shared Instance with Multi-Tenancy**
```bash
# Single n8n instance
├── workflows/ (templates with customer routing)
├── customer-configs.json (customer parameters)
└── credentials/ (per-customer NetBox tokens)
```

**Workflow Status**: ✅ **PERSISTENT** - Workflows adapt via environment variables

### **Model 3: Kubernetes Multi-Tenant**
```yaml
# Namespace per customer
apiVersion: v1
kind: Namespace
metadata:
  name: customer-a
---
# n8n deployment with customer-specific secrets
```

**Workflow Status**: ✅ **PERSISTENT** - Each namespace has isolated storage

## 🔄 **Workflow Migration Process:**

### **Template Export/Import System**
```bash
# Export workflows as templates
./manage-customers.sh export-workflows customer-a

# Deploy to new environment
./manage-customers.sh deploy customer-b --from-template customer-a
```

### **Automated Customer Onboarding**
1. **Create customer environment** (30 seconds)
2. **Import workflow templates** (automated)
3. **Configure customer credentials** (API tokens, URLs)
4. **Test workflow execution** (validation)

## 🛡️ **Security & Isolation Guarantees:**

- **Database Isolation**: Separate PostgreSQL per customer (Model 1)
- **Network Isolation**: Docker networks prevent cross-customer access
- **Credential Separation**: Each customer has own NetBox tokens
- **Data Encryption**: TLS for all API communications

## 📊 **Performance Impact:**

- **Single Template**: One workflow serves multiple customers
- **Resource Sharing**: Efficient CPU/memory usage (Model 2)
- **Scale Flexibility**: Add customers without rebuilding workflows
- **Zero Downtime**: Customer onboarding doesn't affect existing workflows

## 🎯 **Real-World Example:**

```json
{
  "customer_a": {
    "netbox_url": "https://customer-a-netbox.internal",
    "api_token": "abc123...",
    "workflows_deployed": ["device-discovery", "ipam-mgmt", "compliance"]
  },
  "customer_b": {
    "netbox_url": "https://customer-b-netbox.internal", 
    "api_token": "def456...",
    "workflows_deployed": ["device-discovery", "ipam-mgmt", "compliance"]
  }
}
```

**Same workflows, different NetBox endpoints, completely isolated data!**

## 🚀 **Ready-to-Use Commands:**

```bash
# Add new customer (workflows auto-deploy)
./manage-customers.sh add "Customer-C" "https://customer-c.netbox.local" "token123"

# Deploy to isolated environment
./manage-customers.sh deploy customer-c --isolated

# Verify workflow persistence
./manage-customers.sh list --show-workflows
```

## 🔑 **Key Takeaway:**
Your n8n workflows are **templates** that adapt to each customer's environment through configuration, not rebuilding. Deploy once, serve many customers! 🎉
