# Intent-Based Network Service Workflow - Detailed Architecture

## High-Level Architecture Flow
```
[User Request] → [n8n Workflow] → [Network Infrastructure] → [Audit System]
      ↓               ↓                     ↓                     ↓
  Intent Input   TFS Tracking        Live Changes         Compliance Log
```

## Detailed Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            TRIGGER & INITIALIZATION                            │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
┌─────────────────┐    INPUT METHODS    │    ┌─────────────────┐
│   WEBHOOK       │◄───────────────────────►│   MANUAL        │
│  (External API) │                         │  (User Click)   │
│                 │    ┌─────────────────┐   │                 │
│ - POST /intent  │    │     CRON        │   │ - Start Button  │
│ - JSON payload  │    │   (Schedule)    │   │ - Form Input    │
│ - Auth headers  │    │                 │   │ - Parameters    │
└─────────┬───────┘    │ - Daily 2AM     │   └─────────┬───────┘
          │            │ - Weekly maint  │             │
          │            │ - Event based   │             │
          │            └─────────┬───────┘             │
          └──────────────────────┼─────────────────────┘
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           TFS CHANGE NUMBER GENERATION                         │
└─────────────────────────────────────────────────────────────────────────────────┘
                                 │
               ┌─────────────────┐│┌─────────────────┐
               │  CODE NODE      │││  JAVASCRIPT     │
               │  (JavaScript)   │││  FUNCTION       │
               │                 │││                 │
               │ function gen()  │││ Math.random()   │
               │ TFS + 6 digits  │││ 100000-999999   │
               │ Unique each run │││ String concat   │
               └─────────────────┘│└─────────────────┘
                                 ▼
                    OUTPUT: TFS{XXXXXX}
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           VARIABLE INITIALIZATION                              │
└─────────────────────────────────────────────────────────────────────────────────┘
                                 │
               ┌─────────────────┐│┌─────────────────┐
               │   SET NODE      │││   VARIABLES     │
               │   (Storage)     │││   CREATED       │
               │                 │││                 │
               │ change_number   │││ TFS123456       │
               │ timestamp       │││ 2025-08-11T...  │
               │ user_id         │││ admin_user      │
               │ request_source  │││ webhook/manual  │
               │ workflow_id     │││ uuid-generated  │
               │ priority        │││ high/med/low    │
               └─────────────────┘│└─────────────────┘
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            INTENT PARSING & ANALYSIS                           │
└─────────────────────────────────────────────────────────────────────────────────┘
                                 │
               ┌─────────────────┐│┌─────────────────┐
               │  CODE NODE      │││  PARSE LOGIC    │
               │  (JavaScript)   │││                 │
               │                 │││ JSON.parse()    │
               │ Intent Types:   │││ Validate schema │
               │ - VLAN create   │││ Extract params  │
               │ - Route add     │││ Set defaults    │
               │ - QoS policy    │││ Error handling  │
               │ - ACL update    │││ Type checking   │
               │ - Port config   │││ Range validation│
               └─────────────────┘│└─────────────────┘
                                 ▼
                    STRUCTURED INTENT DATA
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          VALIDATION & SECURITY CHECKS                          │
└─────────────────────────────────────────────────────────────────────────────────┘
                                 │
               ┌─────────────────┐│┌─────────────────┐
               │   IF NODE       │││  VALIDATION     │
               │  (Decision)     │││  RULES          │
               │                 │││                 │
               │ Policy Check:   │││ IP range valid  │
               │ - IP conflicts  │││ VLAN available  │
               │ - VLAN limits   │││ User authorized │
               │ - Auth perms    │││ Resource limits │
               │ - Resource cap  │││ Conflict detect │
               │ - Time windows  │││ Maintenance win │
               └─────┬───────────┘│└─────────────────┘
                     │            │
          ┌──────────┼────────────┼──────────┐
          │          │            │          │
     INVALID      VALID       WARNING    REQUIRES_APPROVAL
          │          │            │          │
          ▼          ▼            ▼          ▼
    ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
    │ REJECT  │ │PROCEED  │ │ WARN &  │ │APPROVAL │
    │ & LOG   │ │TO APPLY │ │PROCEED  │ │WORKFLOW │
    └─────────┘ └─────────┘ └─────────┘ └─────────┘
          │          │            │          │
          └──────────┼────────────┼──────────┘
                     ▼            ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        NETWORK INFRASTRUCTURE INTERFACE                        │
└─────────────────────────────────────────────────────────────────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  SDN CONTROLLER │    │  TRADITIONAL    │    │  CLOUD API      │
│  (HTTP REST)    │    │  DEVICES        │    │  (REST/GraphQL) │
│                 │    │  (SSH/NETCONF)  │    │                 │
│ - OpenDaylight  │    │                 │    │ - AWS VPC       │
│ - ONOS          │    │ - Cisco IOS     │    │ - Azure vNet    │
│ - Floodlight    │    │ - Juniper       │    │ - GCP Networks  │
│ - Custom APIs   │    │ - Arista        │    │ - VMware NSX    │
│                 │    │ - HP/HPE        │    │                 │
│ POST /flows     │    │ SSH Commands:   │    │ API Calls:      │
│ {flow_rules}    │    │ vlan database   │    │ CreateSubnet    │
│ TFS: 123456     │    │ interface conf  │    │ AttachRouteTable│
└─────────┬───────┘    │ route add       │    │ ModifySecGroup  │
          │            └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            CONFIGURATION EXECUTION                             │
└─────────────────────────────────────────────────────────────────────────────────┘
                                 │
               ┌─────────────────┐│┌─────────────────┐
               │ HTTP REQUEST    │││  EXECUTION      │
               │   NODES         │││   DETAILS       │
               │                 │││                 │
               │ Method: POST    │││ Timeout: 30s    │
               │ Headers:        │││ Retries: 3      │
               │ - Auth token    │││ Backoff: exp    │
               │ - Content-Type  │││ Error capture   │
               │ - TFS-ID        │││ Response log    │
               │ - Timestamp     │││ Status codes    │
               │                 │││ - 200: Success  │
               │ Body includes:  │││ - 4xx: Client   │
               │ - Config data   │││ - 5xx: Server   │
               │ - TFS number    │││ - Timeout: Fail │
               └─────────────────┘│└─────────────────┘
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           VERIFICATION & TESTING                               │
└─────────────────────────────────────────────────────────────────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ CONFIG CHECK    │    │ CONNECTIVITY    │    │ PERFORMANCE     │
│ (HTTP GET)      │    │ TEST (PING)     │    │ TEST (IPERF)    │
│                 │    │                 │    │                 │
│ Verify applied: │    │ Test paths:     │    │ Measure:        │
│ - VLAN exists   │    │ - End-to-end    │    │ - Throughput    │
│ - Routes active │    │ - Gateway reach │    │ - Latency       │
│ - ACLs loaded   │    │ - DNS resolution│    │ - Packet loss   │
│ - QoS enabled   │    │ - Service ports │    │ - Jitter        │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              RESULT PROCESSING                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
                                 │
               ┌─────────────────┐│┌─────────────────┐
               │   IF NODE       │││  RESULT         │
               │  (Decision)     │││  EVALUATION     │
               │                 │││                 │
               │ Success Path:   │││ All tests pass  │
               │ - All verified  │││ Config applied  │
               │ - Tests pass    │││ No errors       │
               │ - No errors     │││                 │
               │                 │││ Failure Path:   │
               │ Failure Path:   │││ Verification    │
               │ - Config failed │││ failed          │
               │ - Tests failed  │││ Tests failed    │
               │ - Timeouts      │││ Rollback needed │
               └─────┬───────────┘│└─────────────────┘
                     │            │
          ┌──────────┼────────────┼──────────┐
          │          │            │          │
      SUCCESS    PARTIAL      FAILURE    ROLLBACK
          │          │            │          │
          ▼          ▼            ▼          ▼
    ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
    │SUCCESS  │ │ PARTIAL │ │ FAILED  │ │ROLLBACK │
    │NOTIFY   │ │ WARN    │ │ ERROR   │ │RESTORE  │
    └─────────┘ └─────────┘ └─────────┘ └─────────┘
          │          │            │          │
          └──────────┼────────────┼──────────┘
                     ▼            ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        NOTIFICATION & REPORTING                                │
└─────────────────────────────────────────────────────────────────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     EMAIL       │    │     SLACK       │    │    WEBHOOK      │
│   (SMTP Node)   │    │   (HTTP POST)   │    │  (HTTP POST)    │
│                 │    │                 │    │                 │
│ To: NetOps team │    │ Channel:        │    │ External ITSM:  │
│ Subject:        │    │ #network-ops    │    │ - ServiceNow    │
│ "TFS123456      │    │                 │    │ - Remedy        │
│  Completed"     │    │ Message:        │    │ - Jira          │
│                 │    │ "🟢 Success     │    │                 │
│ Body includes:  │    │  TFS123456      │    │ Payload:        │
│ - Status        │    │  VLAN created"  │    │ - Incident ID   │
│ - Details       │    │                 │    │ - Status update │
│ - Timestamp     │    │ Attachments:    │    │ - TFS reference │
│ - Log links     │    │ - Config diff   │    │ - Change record │
└─────────┬───────┘    │ - Test results  │    └─────────┬───────┘
          │            └─────────┬───────┘              │
          └──────────────────────┼──────────────────────┘
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           AUDIT & COMPLIANCE LOGGING                           │
└─────────────────────────────────────────────────────────────────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   DATABASE      │    │   SIEM/LOG      │    │   COMPLIANCE    │
│   (PostgreSQL)  │    │   (Splunk/ELK)  │    │   (GRC Tools)   │
│                 │    │                 │    │                 │
│ Tables:         │    │ Log Format:     │    │ Reports:        │
│ - changes       │    │ RFC3164/5424    │    │ - SOX           │
│ - audit_trail   │    │                 │    │ - PCI-DSS       │
│ - approvals     │    │ Fields:         │    │ - HIPAA         │
│ - rollbacks     │    │ - timestamp     │    │ - ISO27001      │
│                 │    │ - severity      │    │                 │
│ Stored data:    │    │ - tfs_id        │    │ Evidence:       │
│ - TFS: 123456   │    │ - user_id       │    │ - Who changed   │
│ - User: admin   │    │ - action        │    │ - What changed  │
│ - Intent: VLAN  │    │ - result        │    │ - When changed  │
│ - Status: OK    │    │ - device_ip     │    │ - Why changed   │
│ - Duration: 45s │    │ - config_hash   │    │ - Approval      │
│ - Config_diff   │    │                 │    │ - Verification  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Detailed Node Configuration Examples

### 1. START NODE (Webhook Configuration)
```json
{
  "httpMethod": "POST",
  "path": "/network-intent",
  "authentication": "headerAuth",
  "authPropertyName": "x-api-key",
  "responseMode": "responseNode",
  "options": {
    "rawBody": true
  }
}
```

### 2. TFS GENERATOR (Code Node - JavaScript)
```javascript
// Enhanced TFS Generator with collision detection
function generateChangeNumber() {
  const timestamp = new Date().getTime().toString().slice(-4);
  const randomNum = Math.floor(10 + Math.random() * 90); // 2 digits
  return `TFS${timestamp}${randomNum}`;
}

function validateUnique(tfsNumber) {
  // In production, check against database
  // For now, return true
  return true;
}

let tfsNumber;
let attempts = 0;
do {
  tfsNumber = generateChangeNumber();
  attempts++;
} while (!validateUnique(tfsNumber) && attempts < 10);

return [{
  json: {
    change_number: tfsNumber,
    generation_timestamp: new Date().toISOString(),
    attempts: attempts,
    workflow_instance_id: $executionId
  }
}];
```

### 3. SET NODE Configuration
```json
{
  "values": {
    "change_number": "={{$json['change_number']}}",
    "timestamp": "={{$now.toISO()}}",
    "user_id": "={{$json['headers']['x-user-id'] || 'system'}}",
    "request_source": "={{$json['headers']['user-agent'] || 'direct'}}",
    "workflow_id": "={{$executionId}}",
    "priority": "={{$json['priority'] || 'medium'}}",
    "environment": "={{$json['environment'] || 'production'}}",
    "request_payload": "={{$json}}"
  },
  "keepOnlySet": false
}
```

### 4. INTENT PARSER (Code Node - JavaScript)
```javascript
// Comprehensive Intent Parser
function parseNetworkIntent(payload) {
  const intent = payload.intent || {};
  const intentType = intent.type || 'unknown';
  
  const parsers = {
    'vlan': parseVlanIntent,
    'route': parseRouteIntent,
    'acl': parseAclIntent,
    'qos': parseQosIntent,
    'interface': parseInterfaceIntent
  };
  
  if (!parsers[intentType]) {
    throw new Error(`Unsupported intent type: ${intentType}`);
  }
  
  return parsers[intentType](intent);
}

function parseVlanIntent(intent) {
  return {
    type: 'vlan',
    action: intent.action || 'create', // create, modify, delete
    vlan_id: parseInt(intent.vlan_id),
    name: intent.name,
    description: intent.description,
    subnets: intent.subnets || [],
    tagged_ports: intent.tagged_ports || [],
    untagged_ports: intent.untagged_ports || [],
    validation_rules: {
      vlan_id_range: [1, 4094],
      name_pattern: /^[a-zA-Z0-9_-]{1,32}$/,
      required_fields: ['vlan_id', 'name']
    }
  };
}

function parseRouteIntent(intent) {
  return {
    type: 'route',
    action: intent.action || 'add',
    destination: intent.destination,
    next_hop: intent.next_hop,
    metric: intent.metric || 1,
    interface: intent.interface,
    route_table: intent.route_table || 'main',
    validation_rules: {
      destination_format: /^\d+\.\d+\.\d+\.\d+\/\d+$/,
      next_hop_format: /^\d+\.\d+\.\d+\.\d+$/,
      required_fields: ['destination', 'next_hop']
    }
  };
}

// Main execution
try {
  const parsedIntent = parseNetworkIntent($input.all()[0].json);
  
  return [{
    json: {
      parsed_intent: parsedIntent,
      original_request: $input.all()[0].json,
      parsing_timestamp: new Date().toISOString(),
      tfs_number: $('SET').all()[0].change_number
    }
  }];
} catch (error) {
  return [{
    json: {
      error: true,
      error_message: error.message,
      error_type: 'parsing_error',
      original_request: $input.all()[0].json,
      tfs_number: $('SET').all()[0].change_number
    }
  }];
}
```

### 5. VALIDATION NODE (IF Node Configuration)
```json
{
  "conditions": {
    "string": [
      {
        "value1": "={{$json['error']}}",
        "operation": "notEqual",
        "value2": true
      }
    ],
    "number": [
      {
        "value1": "={{$json['parsed_intent']['vlan_id']}}",
        "operation": "between",
        "value2": 1,
        "value3": 4094
      }
    ],
    "boolean": [
      {
        "value1": "={{$json['parsed_intent']['validation_rules']['required_fields'].every(field => $json['parsed_intent'][field] !== undefined)}}",
        "operation": "equal",
        "value2": true
      }
    ]
  },
  "combineOperation": "all"
}
```

### 6. NETWORK API NODES (HTTP Request Configurations)

#### SDN Controller (OpenDaylight)
```json
{
  "method": "POST",
  "url": "http://{{$env['SDN_CONTROLLER_URL']}}/restconf/config/opendaylight-inventory:nodes",
  "authentication": "basicAuth",
  "username": "{{$env['SDN_USERNAME']}}",
  "password": "{{$env['SDN_PASSWORD']}}",
  "headers": {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "X-TFS-ID": "={{$('SET').all()[0].change_number}}",
    "X-Requested-By": "n8n-workflow"
  },
  "body": {
    "node": {
      "id": "{{$json['parsed_intent']['device_id']}}",
      "flow-node-inventory:switch-features": {
        "flow-node-inventory:max_tables": 254
      }
    }
  },
  "timeout": 30000,
  "redirect": "follow"
}
```

#### Traditional Device (SSH)
```json
{
  "method": "POST",
  "url": "http://{{$env['SSH_PROXY_URL']}}/execute",
  "headers": {
    "Content-Type": "application/json",
    "X-TFS-ID": "={{$('SET').all()[0].change_number}}"
  },
  "body": {
    "host": "{{$json['parsed_intent']['device_ip']}}",
    "username": "{{$env['DEVICE_USERNAME']}}",
    "password": "{{$env['DEVICE_PASSWORD']}}",
    "commands": [
      "configure terminal",
      "vlan {{$json['parsed_intent']['vlan_id']}}",
      "name {{$json['parsed_intent']['name']}}",
      "exit",
      "write memory"
    ],
    "timeout": 60,
    "tfs_id": "={{$('SET').all()[0].change_number}}"
  }
}
```

### 7. VERIFICATION NODES

#### Config Verification
```javascript
// Verification Code Node
async function verifyConfiguration(intent, deviceResponse) {
  const verificationType = intent.type;
  
  switch (verificationType) {
    case 'vlan':
      return await verifyVlanConfiguration(intent, deviceResponse);
    case 'route':
      return await verifyRouteConfiguration(intent, deviceResponse);
    default:
      return { verified: false, reason: 'Unknown intent type' };
  }
}

async function verifyVlanConfiguration(intent, response) {
  // Parse device response to verify VLAN was created
  const vlanExists = response.includes(`vlan ${intent.vlan_id}`);
  const nameCorrect = response.includes(intent.name);
  
  return {
    verified: vlanExists && nameCorrect,
    details: {
      vlan_exists: vlanExists,
      name_correct: nameCorrect,
      verification_timestamp: new Date().toISOString()
    }
  };
}

// Execute verification
const intent = $('INTENT PARSER').all()[0].json.parsed_intent;
const deviceResponse = $input.all()[0].json;

const verification = await verifyConfiguration(intent, deviceResponse);

return [{
  json: {
    verification_result: verification,
    intent: intent,
    device_response: deviceResponse,
    tfs_number: $('SET').all()[0].change_number
  }
}];
```

### 8. NOTIFICATION NODES

#### Email Node Configuration
```json
{
  "fromEmail": "netops@company.com",
  "toEmail": "{{$json['parsed_intent']['notification_recipients'] || 'admin@company.com'}}",
  "subject": "[{{$json['verification_result']['verified'] ? 'SUCCESS' : 'FAILED'}}] Network Change {{$('SET').all()[0].change_number}}",
  "text": "Network Intent Execution Report\n\nTFS Number: {{$('SET').all()[0].change_number}}\nIntent Type: {{$json['intent']['type']}}\nStatus: {{$json['verification_result']['verified'] ? 'SUCCESS' : 'FAILED'}}\nTimestamp: {{$now.toISO()}}\nDevice: {{$json['intent']['device_ip']}}\n\nDetails:\n{{JSON.stringify($json['verification_result']['details'], null, 2)}}",
  "html": "<h2>Network Intent Execution Report</h2><table><tr><td>TFS Number:</td><td>{{$('SET').all()[0].change_number}}</td></tr><tr><td>Intent Type:</td><td>{{$json['intent']['type']}}</td></tr><tr><td>Status:</td><td><span style='color: {{$json['verification_result']['verified'] ? 'green' : 'red'}}'>{{$json['verification_result']['verified'] ? 'SUCCESS' : 'FAILED'}}</span></td></tr></table>"
}
```

#### Slack Node Configuration
```json
{
  "channel": "#network-operations",
  "text": "{{$json['verification_result']['verified'] ? '✅' : '❌'}} Network Change {{$('SET').all()[0].change_number}}",
  "attachments": [
    {
      "color": "{{$json['verification_result']['verified'] ? 'good' : 'danger'}}",
      "fields": [
        {
          "title": "TFS Number",
          "value": "{{$('SET').all()[0].change_number}}",
          "short": true
        },
        {
          "title": "Intent Type",
          "value": "{{$json['intent']['type']}}",
          "short": true
        },
        {
          "title": "Device",
          "value": "{{$json['intent']['device_ip']}}",
          "short": true
        },
        {
          "title": "Status",
          "value": "{{$json['verification_result']['verified'] ? 'SUCCESS' : 'FAILED'}}",
          "short": true
        }
      ]
    }
  ]
}
```

### 9. AUDIT LOG NODE (Database)
```json
{
  "method": "POST",
  "url": "{{$env['AUDIT_DB_URL']}}/api/audit-logs",
  "headers": {
    "Content-Type": "application/json",
    "Authorization": "Bearer {{$env['AUDIT_DB_TOKEN']}}"
  },
  "body": {
    "tfs_number": "={{$('SET').all()[0].change_number}}",
    "timestamp": "={{$now.toISO()}}",
    "user_id": "={{$('SET').all()[0].user_id}}",
    "intent_type": "={{$json['intent']['type']}}",
    "intent_details": "={{$json['intent']}}",
    "execution_status": "={{$json['verification_result']['verified'] ? 'SUCCESS' : 'FAILED'}}",
    "device_ip": "={{$json['intent']['device_ip']}}",
    "verification_details": "={{$json['verification_result']}}",
    "workflow_execution_id": "={{$executionId}}",
    "environment": "={{$('SET').all()[0].environment}}",
    "duration_seconds": "={{Math.round(($now.toMillis() - new Date($('SET').all()[0].timestamp).getTime()) / 1000)}}",
    "rollback_available": true,
    "compliance_tags": ["SOX", "PCI-DSS"]
  }
}
```

## Error Handling and Rollback Strategy

### Error Node (On Workflow Error)
```javascript
// Error Handler Code Node
function handleWorkflowError(error, context) {
  const errorInfo = {
    tfs_number: context.tfs_number || 'N/A',
    error_type: error.name || 'Unknown',
    error_message: error.message,
    stack_trace: error.stack,
    failed_node: error.node || 'Unknown',
    timestamp: new Date().toISOString(),
    rollback_required: true
  };
  
  // Determine rollback strategy
  if (context.intent && context.intent.type) {
    errorInfo.rollback_commands = generateRollbackCommands(context.intent);
  }
  
  return errorInfo;
}

function generateRollbackCommands(intent) {
  switch (intent.type) {
    case 'vlan':
      return [
        'configure terminal',
        `no vlan ${intent.vlan_id}`,
        'write memory'
      ];
    case 'route':
      return [
        'configure terminal',
        `no ip route ${intent.destination} ${intent.next_hop}`,
        'write memory'
      ];
    default:
      return [];
  }
}

// Execute error handling
const error = $input.all()[0].json.error;
const context = {
  tfs_number: $('SET').all()?.[0]?.change_number,
  intent: $('INTENT PARSER').all()?.[0]?.json?.parsed_intent
};

return [{ json: handleWorkflowError(error, context) }];
```

## Performance Monitoring

### Execution Time Tracking
```javascript
// Performance Monitor Code Node
const startTime = new Date($('SET').all()[0].timestamp).getTime();
const currentTime = Date.now();
const executionTime = currentTime - startTime;

const performanceMetrics = {
  tfs_number: $('SET').all()[0].change_number,
  total_execution_time_ms: executionTime,
  parsing_time_ms: new Date($('INTENT PARSER').all()[0].json.parsing_timestamp).getTime() - startTime,
  network_api_response_time_ms: 0, // To be calculated from HTTP response times
  verification_time_ms: 0, // To be calculated
  workflow_efficiency: executionTime < 60000 ? 'Good' : executionTime < 120000 ? 'Fair' : 'Poor',
  timestamp: new Date().toISOString()
};

return [{ json: performanceMetrics }];
```

## Data Flow

1. **Intent Input** → TFS Number Generation
2. **TFS Number** → Used in all subsequent API calls
3. **Validation** → Determines workflow path
4. **Success/Failure** → Triggers appropriate notifications
5. **Audit Trail** → Complete tracking for compliance

## Error Handling

- Each HTTP node should have error handling
- Failed validations trigger error notifications
- All errors include TFS number for tracking
- Rollback procedures can reference TFS number
