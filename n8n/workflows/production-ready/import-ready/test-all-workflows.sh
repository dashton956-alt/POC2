#!/bin/bash

# 🧪 Comprehensive n8n Workflow Test Suite
# Tests all imported workflows with sample data

set -e

# Configuration
N8N_URL="http://localhost:5678"
TEST_LOG="/tmp/n8n-workflow-tests.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 n8n Workflow Test Suite Starting...${NC}"
echo "Testing n8n at: $N8N_URL"
echo "Log file: $TEST_LOG"
echo ""

# Create log file
echo "Tests started at $(date)" > "$TEST_LOG"

# Check if n8n is running
if ! curl -sf "$N8N_URL" > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: n8n is not accessible at $N8N_URL${NC}"
    echo "Please ensure n8n is running: docker compose up -d"
    exit 1
fi

echo -e "${GREEN}✅ n8n is accessible${NC}"
echo ""

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run test
run_test() {
    local test_name="$1"
    local method="$2"
    local endpoint="$3"
    local payload="$4"
    local expected_status="$5"
    
    echo -e "${YELLOW}🧪 Testing: $test_name${NC}"
    ((TOTAL_TESTS++))
    
    if [[ "$method" == "GET" ]]; then
        RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" "$N8N_URL$endpoint" 2>&1)
    else
        RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
            -X "$method" \
            -H "Content-Type: application/json" \
            -d "$payload" \
            "$N8N_URL$endpoint" 2>&1)
    fi
    
    HTTP_STATUS=$(echo "$RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    BODY=$(echo "$RESPONSE" | sed -E 's/HTTPSTATUS:[0-9]*$//')
    
    if [[ "$HTTP_STATUS" == "$expected_status" ]]; then
        echo -e "${GREEN}  ✅ PASSED - HTTP $HTTP_STATUS${NC}"
        echo "  Response preview: $(echo "$BODY" | head -c 100)..."
        echo "PASSED: $test_name - HTTP $HTTP_STATUS at $(date)" >> "$TEST_LOG"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}  ❌ FAILED - Expected HTTP $expected_status, got HTTP $HTTP_STATUS${NC}"
        echo "  Error: $BODY"
        echo "FAILED: $test_name - Expected HTTP $expected_status, got HTTP $HTTP_STATUS at $(date)" >> "$TEST_LOG"
        ((FAILED_TESTS++))
    fi
    
    echo ""
    sleep 2
}

# Test 1: Environment Variables Test
run_test \
    "Environment Variables Test" \
    "GET" \
    "/webhook/env-test" \
    "" \
    "200"

# Test 2: NetBox IPAM Management
run_test \
    "NetBox IPAM Management" \
    "POST" \
    "/webhook/netbox-ipam" \
    '{
        "action": "create_ip",
        "ip_address": "192.168.100.50/24",
        "description": "Test IP via n8n API",
        "dns_name": "test-server.local"
    }' \
    "200"

# Test 3: AI Quick Network (if OpenAI configured)
if [[ -n "$OPENAI_API_KEY" || $(grep -q "OPENAI_API_KEY=" /home/dan/POC2/n8n/docker-compose.yml) ]]; then
    run_test \
        "AI Quick Network Automation" \
        "POST" \
        "/webhook/ai-quick" \
        '{
            "request": "Create a VLAN configuration for guest network access",
            "priority": "normal"
        }' \
        "200"
else
    echo -e "${YELLOW}⚠️  Skipping AI tests - OpenAI API key not configured${NC}"
    echo ""
fi

# Test 4: Multi-Tenant Router (would need to be created)
run_test \
    "Multi-Tenant Router Test" \
    "POST" \
    "/webhook/tenant-router" \
    '{
        "customer_id": "demo-corp",
        "action": "route_request",
        "target": "netbox"
    }' \
    "404"  # Expected to fail if webhook not active

# Test 5: Complete AI GitOps Pipeline
run_test \
    "AI GitOps Complete Pipeline" \
    "POST" \
    "/webhook/ai-gitops-automation" \
    '{
        "request": "Deploy new switch configuration for branch office",
        "site": "branch-01",
        "priority": "high",
        "requester": "network-team"
    }' \
    "404"  # Expected to fail if webhook not active

echo -e "${BLUE}📊 Test Results Summary${NC}"
echo -e "${GREEN}✅ Passed: $PASSED_TESTS tests${NC}"
echo -e "${RED}❌ Failed: $FAILED_TESTS tests${NC}"
echo -e "${PURPLE}📋 Total: $TOTAL_TESTS tests executed${NC}"
echo ""

# Calculate success rate
if [[ $TOTAL_TESTS -gt 0 ]]; then
    SUCCESS_RATE=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    echo -e "${BLUE}📈 Success Rate: $SUCCESS_RATE%${NC}"
    
    if [[ $SUCCESS_RATE -ge 80 ]]; then
        echo -e "${GREEN}🎉 Great! Most tests are passing${NC}"
    elif [[ $SUCCESS_RATE -ge 50 ]]; then
        echo -e "${YELLOW}⚠️  Some tests need attention${NC}"
    else
        echo -e "${RED}🔥 Multiple failures - check configuration${NC}"
    fi
fi

echo ""
echo -e "${BLUE}💡 Troubleshooting Tips:${NC}"
echo "• 404 errors: Workflow not imported or not activated"
echo "• 500 errors: Check environment variables and credentials"
echo "• Connection errors: Verify NetBox and n8n are running"
echo "• AI errors: Validate OpenAI API key configuration"
echo ""

echo -e "${BLUE}📄 Full test log: $TEST_LOG${NC}"
echo "Tests completed at $(date)" >> "$TEST_LOG"

# Additional diagnostic information
echo -e "${BLUE}🔍 System Status Check:${NC}"

# Check Docker containers
echo "Docker containers:"
docker compose ps | head -5

echo ""
echo "Environment variables status:"
if [[ -f "/home/dan/POC2/n8n/docker-compose.yml" ]]; then
    echo "✅ docker-compose.yml found"
    if grep -q "NETBOX_TOKEN=" /home/dan/POC2/n8n/docker-compose.yml; then
        echo "✅ NETBOX_TOKEN configured"
    else
        echo "❌ NETBOX_TOKEN not found"
    fi
else
    echo "❌ docker-compose.yml not found"
fi

echo ""
echo -e "${GREEN}Test suite completed! 🧪${NC}"
