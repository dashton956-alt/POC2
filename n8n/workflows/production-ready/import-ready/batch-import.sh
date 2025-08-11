#!/bin/bash

# 🚀 n8n Workflow Batch Import Script
# This script imports all workflows into n8n via API

set -e

# Configuration
N8N_URL="http://localhost:5678"
IMPORT_DIR="/home/dan/POC2/n8n/import-ready"
LOG_FILE="/tmp/n8n-import.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 n8n Workflow Batch Import Starting...${NC}"
echo "Importing from: $IMPORT_DIR"
echo "n8n URL: $N8N_URL"
echo "Log file: $LOG_FILE"
echo ""

# Create log file
echo "Import started at $(date)" > "$LOG_FILE"

# Check if n8n is running
if ! curl -sf "$N8N_URL" > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: n8n is not accessible at $N8N_URL${NC}"
    echo "Please ensure n8n is running: docker compose up -d"
    exit 1
fi

echo -e "${GREEN}✅ n8n is accessible${NC}"
echo ""

# Count JSON files
WORKFLOW_COUNT=$(find "$IMPORT_DIR" -name "*.json" | wc -l)
echo -e "${BLUE}📊 Found $WORKFLOW_COUNT workflows to import${NC}"
echo ""

# Import workflows in recommended order
declare -a WORKFLOWS=(
    "environment-variables-test.json"
    "netbox-connection-test.json"
    "netbox-device-discovery.json"
    "netbox-ipam-management.json"
    "netbox-compliance-monitor.json"
    "netbox-compliance-check-original.json"
    "multi-tenant-netbox-router.json"
    "quick-start-ai-network.json"
    "set_node_config.json"
    "advanced-environment-test.json"
    "ai-gitops-automation-complete.json"
)

IMPORTED=0
FAILED=0

for workflow in "${WORKFLOWS[@]}"; do
    WORKFLOW_FILE="$IMPORT_DIR/$workflow"
    
    if [[ -f "$WORKFLOW_FILE" ]]; then
        echo -e "${YELLOW}📥 Importing: $workflow${NC}"
        
        # Use n8n API to import workflow
        RESPONSE=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d @"$WORKFLOW_FILE" \
            "$N8N_URL/api/v1/workflows/import" 2>&1)
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}  ✅ Successfully imported: $workflow${NC}"
            echo "Successfully imported: $workflow at $(date)" >> "$LOG_FILE"
            ((IMPORTED++))
        else
            echo -e "${RED}  ❌ Failed to import: $workflow${NC}"
            echo "  Error: $RESPONSE"
            echo "Failed to import: $workflow - Error: $RESPONSE at $(date)" >> "$LOG_FILE"
            ((FAILED++))
        fi
        
        # Small delay between imports
        sleep 1
    else
        echo -e "${YELLOW}⚠️  Workflow not found: $workflow${NC}"
        echo "Workflow not found: $workflow at $(date)" >> "$LOG_FILE"
        ((FAILED++))
    fi
    
    echo ""
done

# Summary
echo -e "${BLUE}📊 Import Summary${NC}"
echo -e "${GREEN}✅ Successfully imported: $IMPORTED workflows${NC}"
echo -e "${RED}❌ Failed imports: $FAILED workflows${NC}"
echo ""

if [[ $IMPORTED -gt 0 ]]; then
    echo -e "${GREEN}🎉 Import completed! Next steps:${NC}"
    echo "1. Open n8n: $N8N_URL"
    echo "2. Go to Workflows to see imported workflows"
    echo "3. Configure credentials (NetBox, OpenAI)"
    echo "4. Activate workflows by toggling the 'Active' switch"
    echo "5. Test webhooks using the provided URLs"
    echo ""
    echo -e "${BLUE}📋 Test URLs:${NC}"
    echo "Environment Test: $N8N_URL/webhook/env-test"
    echo "NetBox IPAM: $N8N_URL/webhook/netbox-ipam"
    echo "Multi-Tenant: $N8N_URL/webhook/tenant-router"
    echo "AI Quick: $N8N_URL/webhook/ai-quick"
    echo "AI GitOps: $N8N_URL/webhook/ai-gitops-automation"
fi

echo ""
echo -e "${BLUE}📄 Full log available at: $LOG_FILE${NC}"
echo "Import completed at $(date)" >> "$LOG_FILE"
