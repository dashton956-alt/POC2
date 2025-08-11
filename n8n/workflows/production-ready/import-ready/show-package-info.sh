#!/bin/bash

# 📦 n8n Import Package Summary
# Shows overview of all created workflows and import files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}📦 n8n Workflow Import Package Analysis${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

IMPORT_DIR="/home/dan/POC2/n8n/import-ready"
cd "$IMPORT_DIR"

echo -e "${GREEN}📁 Package Location: $IMPORT_DIR${NC}"
echo ""

# Count files by type
JSON_COUNT=$(find . -name "*.json" -not -name "package-manifest.json" | wc -l)
SCRIPT_COUNT=$(find . -name "*.sh" | wc -l)
DOC_COUNT=$(find . -name "*.md" | wc -l)
TOTAL_FILES=$(find . -maxdepth 1 -type f | wc -l)

echo -e "${CYAN}📊 Package Contents:${NC}"
echo -e "${YELLOW}  • Workflow Files: $JSON_COUNT${NC}"
echo -e "${YELLOW}  • Scripts: $SCRIPT_COUNT${NC}"
echo -e "${YELLOW}  • Documentation: $DOC_COUNT${NC}"
echo -e "${YELLOW}  • Total Files: $TOTAL_FILES${NC}"
echo ""

# Analyze workflows
echo -e "${CYAN}🔧 n8n Workflows Available:${NC}"
echo ""

# Display each workflow with details
declare -a workflows=(
    "environment-variables-test.json|🧪 Environment Variables Test|Test environment setup and connectivity"
    "netbox-connection-test.json|🔗 NetBox Connection Test|Monitor NetBox connectivity every 30 minutes"
    "netbox-device-discovery.json|🔍 NetBox Device Discovery|Discover and monitor devices every 15 minutes"
    "netbox-ipam-management.json|📡 NetBox IPAM Management|REST API for IP address management"
    "netbox-compliance-monitor.json|✅ NetBox Compliance Monitor|Compliance checking every 6 hours"
    "multi-tenant-netbox-router.json|🏢 Multi-Tenant Router|Route requests to customer instances"
    "quick-start-ai-network.json|🤖 Quick AI Network|Simple AI-powered automation"
)

counter=1
for workflow in "${workflows[@]}"; do
    IFS='|' read -r file icon description <<< "$workflow"
    
    if [[ -f "$file" ]]; then
        file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
        file_size_kb=$((file_size / 1024))
        
        echo -e "${GREEN}$counter. $icon${NC}"
        echo -e "   ${YELLOW}File:${NC} $file (${file_size_kb}KB)"
        echo -e "   ${YELLOW}Description:${NC} $description"
        
        # Extract webhook path if it exists
        webhook=$(grep -o '"webhookId": "[^"]*"' "$file" 2>/dev/null | cut -d'"' -f4 || echo "")
        if [[ -n "$webhook" ]]; then
            echo -e "   ${YELLOW}Webhook:${NC} http://localhost:5678/webhook/$webhook"
        else
            echo -e "   ${YELLOW}Trigger:${NC} Scheduled/Manual"
        fi
        
        echo ""
        ((counter++))
    fi
done

# Scripts analysis
echo -e "${CYAN}⚙️ Utility Scripts:${NC}"
echo ""

if [[ -f "batch-import.sh" ]]; then
    echo -e "${GREEN}📥 batch-import.sh${NC}"
    echo "   Import all workflows automatically via n8n API"
    echo "   Usage: ./batch-import.sh"
    echo ""
fi

if [[ -f "test-all-workflows.sh" ]]; then
    echo -e "${GREEN}🧪 test-all-workflows.sh${NC}"
    echo "   Test all workflows with sample data"
    echo "   Usage: ./test-all-workflows.sh"
    echo ""
fi

# Environment requirements
echo -e "${CYAN}🌍 Environment Requirements:${NC}"
echo ""
echo -e "${YELLOW}Required Environment Variables:${NC}"
echo "  • NETBOX_URL=http://localhost:8000"
echo "  • NETBOX_TOKEN=your_netbox_api_token"
echo ""
echo -e "${YELLOW}Optional Environment Variables:${NC}"
echo "  • CUSTOMER_ID=default (for multi-tenant)"
echo "  • OPENAI_API_KEY=sk-... (for AI features)"
echo "  • OPENAI_MODEL=gpt-4 (AI model selection)"
echo "  • GITLAB_URL=https://gitlab.com (for GitOps)"
echo "  • GITLAB_TOKEN=glpat-... (GitLab API access)"
echo ""

# Quick start instructions
echo -e "${CYAN}🚀 Quick Start Instructions:${NC}"
echo ""
echo -e "${GREEN}1. Prerequisites Check:${NC}"
echo "   docker compose ps  # Ensure n8n and NetBox are running"
echo ""
echo -e "${GREEN}2. Import All Workflows:${NC}"
echo "   ./batch-import.sh"
echo ""
echo -e "${GREEN}3. Test Workflows:${NC}"
echo "   ./test-all-workflows.sh"
echo ""
echo -e "${GREEN}4. Access n8n Interface:${NC}"
echo "   http://localhost:5678"
echo ""

# Package validation
echo -e "${CYAN}✅ Package Validation:${NC}"
echo ""

validation_passed=0
validation_total=0

# Check if all expected files exist
expected_files=("README.md" "package-manifest.json" "batch-import.sh" "test-all-workflows.sh")
for file in "${expected_files[@]}"; do
    ((validation_total++))
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✅ $file exists${NC}"
        ((validation_passed++))
    else
        echo -e "${RED}❌ $file missing${NC}"
    fi
done

# Check workflow files
for workflow in *.json; do
    if [[ "$workflow" != "package-manifest.json" ]]; then
        ((validation_total++))
        if [[ -s "$workflow" ]] && grep -q '"name"' "$workflow"; then
            echo -e "${GREEN}✅ $workflow is valid${NC}"
            ((validation_passed++))
        else
            echo -e "${RED}❌ $workflow is invalid${NC}"
        fi
    fi
done

echo ""
echo -e "${BLUE}📈 Validation Score: $validation_passed/$validation_total${NC}"

if [[ $validation_passed -eq $validation_total ]]; then
    echo -e "${GREEN}🎉 Package is complete and ready for import!${NC}"
elif [[ $validation_passed -ge $((validation_total * 80 / 100)) ]]; then
    echo -e "${YELLOW}⚠️  Package is mostly complete but has minor issues${NC}"
else
    echo -e "${RED}🔥 Package has significant issues that need attention${NC}"
fi

echo ""
echo -e "${BLUE}📄 For detailed documentation, see README.md${NC}"
echo -e "${BLUE}📋 For technical details, see package-manifest.json${NC}"
echo ""
echo -e "${PURPLE}🌟 Created: $(date)${NC}"
echo -e "${PURPLE}📍 Repository: https://github.com/dashton956-alt/POC2.git${NC}"
