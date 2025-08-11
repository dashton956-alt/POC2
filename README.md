# POC2 - AI-Powered Network Automation Platform

## 📁 **Project Overview**

This repository contains a comprehensive AI-powered network automation platform built with n8n workflows, NetBox integration, and Docker containerization.

## 🏗️ **Repository Structure**

```
POC2/
├── README.md                    # This file - project overview
├── LICENSE                      # Project license
├── n8n/                        # Main N8N automation platform
│   ├── README.md               # Detailed N8N documentation
│   ├── docker/                 # Docker deployment files
│   ├── config/                 # Configuration templates
│   ├── scripts/                # Automation scripts
│   ├── workflows/              # N8N workflow collections
│   ├── docs/                   # Documentation and guides
│   ├── ai-gitops/             # AI GitOps framework
│   └── monitoring/            # Monitoring configurations
└── netbox-docker/             # NetBox DCIM/IPAM platform
    └── [NetBox Docker setup]
```

## 🚀 **Quick Start**

1. **Clone the repository**
   ```bash
   git clone https://github.com/dashton956-alt/POC2.git
   cd POC2
   ```

2. **Deploy N8N Platform**
   ```bash
   cd n8n
   ./scripts/setup-environment.sh
   cd docker
   docker-compose up -d
   ```

3. **Deploy NetBox (Optional)**
   ```bash
   cd netbox-docker
   docker-compose up -d
   ```

## 🎯 **Key Features**

- **25+ Production-Ready N8N Workflows**
- **AI-Powered GitOps Automation**
- **NetBox DCIM/IPAM Integration**
- **Multi-Tenant Architecture**
- **Docker-Based Deployment**
- **Comprehensive Monitoring**

## 📖 **Documentation**

Detailed documentation is available in the `n8n/docs/` directory:
- **[N8N Platform README](./n8n/README.md)** - Complete platform documentation
- **[Deployment Guide](./n8n/docs/DEPLOYMENT_STEPS.md)** - Step-by-step deployment
- **[Multi-Tenant Setup](./n8n/docs/MULTI_TENANT_GUIDE.md)** - Multi-tenant configuration
- **[Environment Setup](./n8n/docs/N8N_ENVIRONMENT_SETUP.md)** - Environment configuration

---

**Total Workflows**: 25+ ready-to-import N8N workflows  
**Platform**: N8N + NetBox + Docker + AI GitOps  
**Last Updated**: August 2025