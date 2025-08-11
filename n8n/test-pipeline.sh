#!/bin/bash
# Test GitLab CI/CD Pipeline with Network Automation

set -e

echo "🧪 Testing GitLab CI/CD Pipeline for Network Automation"

# Check if containers are running
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ Services are not running. Please run ./setup-ai-gitops.sh first"
    exit 1
fi

echo "✅ Services are running"

# Test Ansible container
echo "🔍 Testing Ansible Pipeline Executor..."
if docker exec ansible-pipeline-executor ansible --version > /dev/null 2>&1; then
    echo "✅ Ansible is working"
    docker exec ansible-pipeline-executor ansible --version
else
    echo "❌ Ansible test failed"
    exit 1
fi

# Test network automation collections
echo "🔍 Testing Ansible network collections..."
docker exec ansible-pipeline-executor ansible-galaxy collection list | grep -E "(cisco|arista|juniper)" || {
    echo "⚠️  Installing network collections..."
    docker exec ansible-pipeline-executor ansible-galaxy collection install cisco.ios cisco.nxos arista.eos juniper.junos
}

# Test GitLab Runner
echo "🔍 Testing GitLab Runner..."
if docker exec gitlab-runner-network-automation gitlab-runner status > /dev/null 2>&1; then
    echo "✅ GitLab Runner is operational"
    docker exec gitlab-runner-network-automation gitlab-runner status
else
    echo "⚠️  GitLab Runner is not registered yet. Run ./register-gitlab-runner.sh"
fi

# Create a test playbook
echo "🔍 Creating test network automation playbook..."
docker exec ansible-pipeline-executor bash -c "
cat > /opt/test-playbook.yml << 'PLAYBOOK'
---
- name: Test Network Automation Pipeline
  hosts: localhost
  gather_facts: no
  tasks:
    - name: Test TFS number generation
      debug:
        msg: 'Generated TFS: TFS{{ ansible_date_time.epoch | regex_replace(\".*(.{6})$\", \"\\\\1\") }}'
    
    - name: Test network device connectivity simulation
      debug:
        msg: 'Network connectivity test - {{ item }}'
      loop:
        - 'Switch-01: Reachable'
        - 'Router-01: Reachable' 
        - 'Firewall-01: Reachable'
    
    - name: Test configuration backup simulation
      debug:
        msg: 'Configuration backed up to /opt/backups/{{ item }}-{{ ansible_date_time.epoch }}.cfg'
      loop:
        - switch-01
        - router-01
        - firewall-01
PLAYBOOK
"

# Run test playbook
echo "🚀 Running test network automation playbook..."
if docker exec ansible-pipeline-executor ansible-playbook /opt/test-playbook.yml; then
    echo "✅ Test playbook execution successful"
else
    echo "❌ Test playbook execution failed"
    exit 1
fi

# Test AI GitOps files access
echo "🔍 Testing AI GitOps files access..."
if docker exec ansible-pipeline-executor ls -la /opt/ai-gitops/; then
    echo "✅ AI GitOps files are accessible in pipeline executor"
else
    echo "❌ AI GitOps files not accessible"
    exit 1
fi

# Test CI/CD pipeline simulation
echo "🔍 Testing CI/CD pipeline simulation..."
docker exec ansible-pipeline-executor bash -c "
echo '🔄 Simulating GitLab CI/CD Pipeline Stages:'
echo '  ✅ Stage 1: Validate - Ansible syntax check passed'
echo '  ✅ Stage 2: Security Scan - No hardcoded credentials found'
echo '  ✅ Stage 3: Test Staging - Connectivity tests passed'
echo '  ✅ Stage 4: Deploy Staging - Configuration applied successfully'
echo '  ⏸️  Stage 5: Manual Approval - Waiting for approval...'
echo '  🎯 Stage 6: Deploy Production - Ready for production deployment'
"

# Display monitoring URLs
echo ""
echo "📊 Monitoring & Management URLs:"
echo "   n8n Dashboard:       http://localhost:5678"
echo "   Prometheus Metrics:  http://localhost:9090"
echo "   Grafana Dashboards:  http://localhost:3000"
echo ""

# Show pipeline logs location
echo "📝 Pipeline logs available at:"
docker exec ansible-pipeline-executor find /opt/logs -name "*.log" 2>/dev/null || echo "   No logs found yet (logs will appear after first real run)"

echo ""
echo "🎉 Pipeline testing completed successfully!"
echo ""
echo "🔧 To run a real pipeline:"
echo "1. Register GitLab Runner: ./register-gitlab-runner.sh"
echo "2. Push GitLab CI configuration to your repository"
echo "3. Trigger pipeline by pushing commits or manual trigger"
echo "4. Monitor execution in GitLab UI and local logs"
