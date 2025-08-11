# n8n Workflow Implementation - AI GitOps Network Automation

## Workflow Nodes Configuration

### 1. AI Intent Processor (Code Node)
```javascript
// AI-powered intent processing with OpenAI
async function processNetworkIntent(userInput) {
  const openaiPrompt = `
    You are a network automation expert. Convert this user request into structured network configuration data.
    
    User Request: "${userInput}"
    
    Return JSON with:
    - action: (create, modify, delete, query)
    - type: (vlan, route, acl, interface, qos)
    - parameters: (specific config details)
    - location: (site/datacenter)
    - priority: (low, medium, high, emergency)
    - dependencies: (related configs)
    - validation_rules: (safety checks)
    
    Example response:
    {
      "action": "create",
      "type": "vlan",
      "parameters": {
        "vlan_id": 100,
        "name": "Sales_Team",
        "description": "VLAN for Sales team in NYC",
        "subnet": "192.168.100.0/24"
      },
      "location": "NYC_HQ",
      "priority": "medium",
      "dependencies": ["trunk_interfaces", "dhcp_scope"],
      "validation_rules": {
        "vlan_range": [100, 199],
        "name_pattern": "^[A-Za-z_]+$"
      }
    }
  `;

  // Call OpenAI API
  const response = await $http.request({
    method: 'POST',
    url: 'https://api.openai.com/v1/chat/completions',
    headers: {
      'Authorization': `Bearer ${$env.OPENAI_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: {
      model: 'gpt-4',
      messages: [
        { role: 'system', content: 'You are a network automation expert.' },
        { role: 'user', content: openaiPrompt }
      ],
      temperature: 0.3
    }
  });

  const aiResponse = JSON.parse(response.choices[0].message.content);
  
  return [{
    json: {
      ai_processed_intent: aiResponse,
      original_input: userInput,
      tfs_number: generateTFSNumber(),
      processing_timestamp: new Date().toISOString()
    }
  }];
}

// Execute
const userInput = $json.user_request || $json.intent || 'Create VLAN 100 for Sales team';
return await processNetworkIntent(userInput);
```

### 2. NetBox Data Enrichment (HTTP Request Nodes)

#### Get Device Inventory
```json
{
  "method": "GET",
  "url": "{{$env.NETBOX_URL}}/api/dcim/devices/",
  "headers": {
    "Authorization": "Token {{$env.NETBOX_TOKEN}}",
    "Content-Type": "application/json"
  },
  "qs": {
    "site": "={{$json.ai_processed_intent.location}}",
    "status": "active",
    "role": "switch"
  }
}
```

#### Get VLAN Dependencies
```json
{
  "method": "GET", 
  "url": "{{$env.NETBOX_URL}}/api/ipam/vlans/",
  "headers": {
    "Authorization": "Token {{$env.NETBOX_TOKEN}}"
  },
  "qs": {
    "site": "={{$json.ai_processed_intent.location}}",
    "status": "active"
  }
}
```

### 3. AI Playbook Generator (Code Node)
```javascript
// Generate Ansible playbook using AI
async function generateAnsiblePlaybook(intent, netboxData) {
  const playbookPrompt = `
    Generate an Ansible playbook for this network change:
    
    Intent: ${JSON.stringify(intent)}
    NetBox Data: ${JSON.stringify(netboxData)}
    
    Requirements:
    - Use best practices for network automation
    - Include error handling and rollback
    - Add validation tasks
    - Follow company standards
    - Include proper variable substitution
    
    Generate YAML playbook with:
    - Pre-tasks (backup, validation)
    - Main tasks (configuration)  
    - Post-tasks (verification)
    - Handlers (rollback on failure)
    - Tests (connectivity checks)
  `;

  const response = await $http.request({
    method: 'POST',
    url: 'https://api.openai.com/v1/chat/completions',
    headers: {
      'Authorization': `Bearer ${$env.OPENAI_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: {
      model: 'gpt-4',
      messages: [
        { 
          role: 'system', 
          content: 'You are an expert in Ansible network automation. Generate production-ready playbooks with proper error handling and rollback procedures.' 
        },
        { role: 'user', content: playbookPrompt }
      ],
      temperature: 0.1
    }
  });

  const playbookContent = response.choices[0].message.content;
  
  // Generate inventory file
  const inventoryContent = generateInventoryFile(netboxData.devices);
  
  // Generate variables file
  const varsContent = generateVariablesFile(intent, netboxData);
  
  return [{
    json: {
      playbook_content: playbookContent,
      inventory_content: inventoryContent,
      variables_content: varsContent,
      tests_content: generateTestsFile(intent),
      rollback_content: generateRollbackFile(intent),
      tfs_number: $('SET').all()[0].change_number
    }
  }];
}

function generateInventoryFile(devices) {
  let inventory = '[network_devices]\n';
  devices.forEach(device => {
    inventory += `${device.name} ansible_host=${device.primary_ip4.address.split('/')[0]} ansible_network_os=${device.platform.slug}\n`;
  });
  return inventory;
}

function generateVariablesFile(intent, netboxData) {
  return JSON.stringify({
    change_request: intent,
    netbox_data: netboxData,
    backup_location: '/opt/backups',
    rollback_enabled: true,
    validation_tests: true
  }, null, 2);
}

// Execute
const intent = $('AI Intent Processor').all()[0].json.ai_processed_intent;
const netboxData = {
  devices: $('NetBox Devices').all()[0].json,
  vlans: $('NetBox VLANs').all()[0].json
};

return await generateAnsiblePlaybook(intent, netboxData);
```

### 4. Git Repository Operations (HTTP Request Nodes)

#### Create Branch
```json
{
  "method": "POST",
  "url": "{{$env.GITLAB_URL}}/api/v4/projects/{{$env.PROJECT_ID}}/repository/branches",
  "headers": {
    "Authorization": "Bearer {{$env.GITLAB_TOKEN}}",
    "Content-Type": "application/json"
  },
  "body": {
    "branch": "feat/{{$('SET').all()[0].change_number}}-{{$json.ai_processed_intent.type}}-{{$json.ai_processed_intent.parameters.vlan_id}}",
    "ref": "main"
  }
}
```

#### Commit Files
```json
{
  "method": "POST",
  "url": "{{$env.GITLAB_URL}}/api/v4/projects/{{$env.PROJECT_ID}}/repository/commits",
  "headers": {
    "Authorization": "Bearer {{$env.GITLAB_TOKEN}}",
    "Content-Type": "application/json"
  },
  "body": {
    "branch": "={{$json.name}}",
    "commit_message": "[{{$('SET').all()[0].change_number}}] {{$json.ai_processed_intent.action}} {{$json.ai_processed_intent.type}} - AI Generated",
    "actions": [
      {
        "action": "create",
        "file_path": "playbooks/{{$('SET').all()[0].change_number}}/site.yml",
        "content": "={{$('AI Playbook Generator').all()[0].json.playbook_content}}"
      },
      {
        "action": "create", 
        "file_path": "inventories/{{$('SET').all()[0].change_number}}/hosts.yml",
        "content": "={{$('AI Playbook Generator').all()[0].json.inventory_content}}"
      },
      {
        "action": "create",
        "file_path": "group_vars/all.yml", 
        "content": "={{$('AI Playbook Generator').all()[0].json.variables_content}}"
      },
      {
        "action": "create",
        "file_path": "tests/{{$('SET').all()[0].change_number}}/test.yml",
        "content": "={{$('AI Playbook Generator').all()[0].json.tests_content}}"
      },
      {
        "action": "create",
        "file_path": "rollback/{{$('SET').all()[0].change_number}}/rollback.yml",
        "content": "={{$('AI Playbook Generator').all()[0].json.rollback_content}}"
      }
    ]
  }
}
```

### 5. Create Merge Request
```json
{
  "method": "POST",
  "url": "{{$env.GITLAB_URL}}/api/v4/projects/{{$env.PROJECT_ID}}/merge_requests",
  "headers": {
    "Authorization": "Bearer {{$env.GITLAB_TOKEN}}",
    "Content-Type": "application/json"
  },
  "body": {
    "source_branch": "={{$('Create Branch').all()[0].json.name}}",
    "target_branch": "main",
    "title": "[{{$('SET').all()[0].change_number}}] {{$json.ai_processed_intent.action}} {{$json.ai_processed_intent.type}} - {{$json.ai_processed_intent.parameters.name}}",
    "description": "## AI-Generated Network Change\n\n**TFS:** {{$('SET').all()[0].change_number}}\n**Type:** {{$json.ai_processed_intent.type}}\n**Action:** {{$json.ai_processed_intent.action}}\n**Location:** {{$json.ai_processed_intent.location}}\n\n### Details:\n```json\n{{JSON.stringify($json.ai_processed_intent.parameters, null, 2)}}\n```\n\n### Affected Devices:\n{{$('NetBox Devices').all()[0].json.results.map(d => '- ' + d.name).join('\n')}}\n\n### Validation:\n- [ ] Code review completed\n- [ ] Security scan passed\n- [ ] Change request approved\n- [ ] Staging tests passed",
    "assignee_ids": [{{$env.NETWORK_TEAM_LEAD_ID}}],
    "reviewer_ids": [{{$env.SENIOR_NETWORK_ENGINEER_ID}}, {{$env.SECURITY_REVIEWER_ID}}],
    "labels": ["network-automation", "ai-generated", "{{$json.ai_processed_intent.priority}}"]
  }
}
```

### 6. ServiceNow Change Request (HTTP Request Node)
```json
{
  "method": "POST",
  "url": "{{$env.SERVICENOW_URL}}/api/now/table/change_request",
  "headers": {
    "Authorization": "Basic {{$env.SERVICENOW_AUTH}}",
    "Content-Type": "application/json"
  },
  "body": {
    "short_description": "[{{$('SET').all()[0].change_number}}] {{$json.ai_processed_intent.action}} {{$json.ai_processed_intent.type}} - {{$json.ai_processed_intent.parameters.name}}",
    "description": "AI-generated network automation change\n\nTFS: {{$('SET').all()[0].change_number}}\nType: {{$json.ai_processed_intent.type}}\nLocation: {{$json.ai_processed_intent.location}}\n\nDetails:\n{{JSON.stringify($json.ai_processed_intent, null, 2)}}",
    "category": "Network",
    "subcategory": "Infrastructure",
    "priority": "={{$json.ai_processed_intent.priority === 'emergency' ? '1' : $json.ai_processed_intent.priority === 'high' ? '2' : '3'}}",
    "risk": "={{$json.ai_processed_intent.type === 'route' ? 'High' : 'Medium'}}",
    "impact": "={{$json.ai_processed_intent.location === 'Production' ? 'High' : 'Low'}}",
    "requested_by": "network-automation-system",
    "assignment_group": "Network Operations",
    "implementation_plan": "Automated deployment via Ansible playbook after approvals",
    "rollback_plan": "Automated rollback playbook available",
    "test_plan": "Automated validation tests included"
  }
}
```

### 7. Wait for Approvals (Wait Node + HTTP Polling)
```javascript
// Approval Status Check (Code Node)
async function checkApprovalStatus() {
  const mrId = $('Create Merge Request').all()[0].json.iid;
  const crNumber = $('ServiceNow CR').all()[0].json.result.number;
  
  // Check MR approval status
  const mrResponse = await $http.request({
    method: 'GET',
    url: `${$env.GITLAB_URL}/api/v4/projects/${$env.PROJECT_ID}/merge_requests/${mrId}/approvals`,
    headers: { 'Authorization': `Bearer ${$env.GITLAB_TOKEN}` }
  });
  
  // Check ServiceNow CR status  
  const crResponse = await $http.request({
    method: 'GET',
    url: `${$env.SERVICENOW_URL}/api/now/table/change_request?sysparm_query=number=${crNumber}`,
    headers: { 'Authorization': `Basic ${$env.SERVICENOW_AUTH}` }
  });
  
  const mrApproved = mrResponse.approved;
  const crApproved = crResponse.result[0].state === '3'; // Authorized state
  
  return [{
    json: {
      mr_approved: mrApproved,
      cr_approved: crApproved,
      all_approved: mrApproved && crApproved,
      mr_id: mrId,
      cr_number: crNumber,
      tfs_number: $('SET').all()[0].change_number
    }
  }];
}

return await checkApprovalStatus();
```

### 8. CI/CD Pipeline Trigger (HTTP Request Node)
```json
{
  "method": "POST",
  "url": "{{$env.GITLAB_URL}}/api/v4/projects/{{$env.PROJECT_ID}}/pipeline",
  "headers": {
    "Authorization": "Bearer {{$env.GITLAB_TOKEN}}",
    "Content-Type": "application/json"
  },
  "body": {
    "ref": "={{$('Create Branch').all()[0].json.name}}",
    "variables": [
      {
        "key": "TFS_NUMBER",
        "value": "={{$('SET').all()[0].change_number}}"
      },
      {
        "key": "ENVIRONMENT",
        "value": "staging"
      },
      {
        "key": "PLAYBOOK_PATH", 
        "value": "playbooks/{{$('SET').all()[0].change_number}}/site.yml"
      },
      {
        "key": "INVENTORY_PATH",
        "value": "inventories/{{$('SET').all()[0].change_number}}/hosts.yml"
      }
    ]
  }
}
```

### 9. Pipeline Status Monitor (Code Node with Loop)
```javascript
// Monitor CI/CD pipeline status
async function monitorPipeline(pipelineId) {
  let status = 'running';
  let attempts = 0;
  const maxAttempts = 30; // 15 minutes max wait
  
  while (status === 'running' && attempts < maxAttempts) {
    const response = await $http.request({
      method: 'GET',
      url: `${$env.GITLAB_URL}/api/v4/projects/${$env.PROJECT_ID}/pipelines/${pipelineId}`,
      headers: { 'Authorization': `Bearer ${$env.GITLAB_TOKEN}` }
    });
    
    status = response.status;
    
    if (status === 'running') {
      await new Promise(resolve => setTimeout(resolve, 30000)); // Wait 30 seconds
      attempts++;
    }
  }
  
  return [{
    json: {
      pipeline_id: pipelineId,
      final_status: status,
      success: status === 'success',
      duration_minutes: attempts * 0.5,
      tfs_number: $('SET').all()[0].change_number
    }
  }];
}

const pipelineId = $('Trigger Pipeline').all()[0].json.id;
return await monitorPipeline(pipelineId);
```

### 10. Production Deployment (Conditional on Success)
```json
{
  "method": "POST",
  "url": "{{$env.GITLAB_URL}}/api/v4/projects/{{$env.PROJECT_ID}}/pipeline",
  "headers": {
    "Authorization": "Bearer {{$env.GITLAB_TOKEN}}",
    "Content-Type": "application/json"
  },
  "body": {
    "ref": "={{$('Create Branch').all()[0].json.name}}",
    "variables": [
      {
        "key": "TFS_NUMBER",
        "value": "={{$('SET').all()[0].change_number}}"
      },
      {
        "key": "ENVIRONMENT", 
        "value": "production"
      },
      {
        "key": "DEPLOYMENT_MODE",
        "value": "live"
      }
    ]
  }
}
```
