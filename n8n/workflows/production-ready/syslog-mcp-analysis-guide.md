# Syslog MCP Analysis Workflow Guide

## 📋 **Overview**

This workflow integrates with a Model Context Protocol (MCP) server to analyze syslog messages and provide intelligent recommendations for incident response and automated remediation.

## 🏗️ **Architecture**

```
Syslog Message → Parse & Filter → MCP Server Analysis → Process Recommendations → Actions
     ↓                                                                              ↓
  Webhook Input                                                           Slack Alert / Auto-Remediation / Database Storage
```

## 🚀 **Features**

- **Real-time Syslog Processing**: Webhook endpoint for receiving syslog messages
- **Intelligent Analysis**: MCP server integration for AI-powered log analysis
- **Risk Assessment**: Automated risk scoring and severity assessment
- **Smart Recommendations**: Context-aware recommendations and remediation steps
- **Automated Remediation**: Self-healing capabilities for common issues
- **Escalation Management**: Automatic escalation for high-risk incidents
- **Trend Analysis**: Historical pattern recognition and trend analysis
- **Database Storage**: Complete audit trail and analytics

## 📊 **Workflow Components**

### 1. **Syslog Webhook** (`/webhook/syslog`)
- Receives syslog messages via HTTP POST
- Supports RFC3164 and custom syslog formats
- JSON payload with message data

### 2. **Syslog Parser**
- Parses RFC3164 syslog format
- Extracts priority, facility, severity, hostname, tag, message
- Calculates alert levels (CRITICAL, WARNING, INFO)

### 3. **Severity Filter**
- Filters high-severity messages (≤ severity 3 or CRITICAL alert level)
- Reduces noise and focuses on actionable alerts

### 4. **MCP Server Integration**
- Sends parsed syslog data to MCP server for analysis
- Requests comprehensive analysis including:
  - Severity assessment
  - Root cause analysis
  - Remediation recommendations
  - Context-aware insights

### 5. **Recommendation Processing**
- Processes MCP server response
- Formats recommendations and remediation steps
- Calculates action items and automation opportunities

### 6. **Conditional Actions**
- **High Risk (>7)**: Triggers Slack alerts and escalation
- **Auto-Remediation Available**: Prepares automated remediation plan
- **Database Storage**: Stores all analysis results for trending

## 🔧 **Configuration Requirements**

### Environment Variables
```bash
# MCP Server Configuration
MCP_SERVER_URL=http://localhost:3001
MCP_API_TOKEN=your_mcp_api_token

# Notification Configuration  
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/your/slack/webhook

# NetBox Integration (Optional)
NETBOX_URL=http://localhost:8000
NETBOX_TOKEN=your_netbox_token
```

### Database Setup
1. Run the provided SQL schema: `syslog-mcp-analysis-schema.sql`
2. Configure PostgreSQL credentials in n8n
3. Verify database connectivity

### MCP Server Requirements
Your MCP server should accept POST requests to `/analyze` with this format:
```json
{
  "type": "syslog_analysis",
  "data": {
    "message": "raw syslog message",
    "parsed_data": {
      "severity": 3,
      "facility": 16,
      "hostname": "server01",
      "tag": "sshd",
      "timestamp": "Aug 11 12:30:45",
      "severity_name": "Error",
      "facility_name": "local use 0"
    },
    "metadata": {
      "source_ip": "192.168.1.100",
      "received_at": "2025-08-11T12:30:45.123Z",
      "alert_level": "WARNING"
    }
  },
  "analysis_request": {
    "include_recommendations": true,
    "include_severity_assessment": true,
    "include_root_cause_analysis": true,
    "include_remediation_steps": true,
    "context_awareness": true
  }
}
```

### Expected MCP Response Format
```json
{
  "analysis": {
    "confidence_score": 0.95,
    "category": "Security",
    "sub_category": "Authentication",
    "description": "Failed SSH authentication attempt detected"
  },
  "severity_assessment": {
    "level": "WARNING",
    "risk_score": 6.5,
    "impact": "Medium",
    "urgency": "Medium",
    "business_impact": "Low"
  },
  "root_cause_analysis": {
    "probable_cause": "Brute force attack or misconfigured SSH client",
    "contributing_factors": ["Weak password policy", "No rate limiting"],
    "affected_systems": ["server01"],
    "error_patterns": ["authentication failure", "invalid user"]
  },
  "recommendations": [
    {
      "priority": "High",
      "category": "Security",
      "title": "Enable SSH rate limiting",
      "description": "Configure fail2ban or similar tool",
      "estimated_effort": "30 minutes",
      "automation_possible": true,
      "immediate_action": true
    }
  ],
  "remediation_steps": [
    {
      "action": "Block suspicious IP",
      "command": "iptables -A INPUT -s {source_ip} -j DROP",
      "expected_outcome": "Prevent further attacks from source IP",
      "validation": "Check iptables rules and monitor logs",
      "rollback_plan": "iptables -D INPUT -s {source_ip} -j DROP"
    }
  ]
}
```

## 📥 **Usage**

### 1. **Send Syslog Messages**
```bash
# Example webhook call
curl -X POST http://your-n8n-instance/webhook/syslog \
  -H "Content-Type: application/json" \
  -d '{
    "message": "<38>Aug 11 12:30:45 server01 sshd[12345]: Failed password for invalid user admin from 192.168.1.100 port 22 ssh2",
    "source_ip": "192.168.1.100"
  }'
```

### 2. **Webhook Response**
```json
{
  "status": "success",
  "message": "Syslog message processed and analyzed",
  "data": {
    "syslog_id": "syslog_1691760645123_abc123def",
    "analysis_completed": true,
    "recommendations_count": 3,
    "risk_score": 6.5,
    "escalation_required": false,
    "auto_remediation_available": true,
    "processed_at": "2025-08-11T12:30:45.456Z"
  }
}
```

## 📊 **Database Queries**

### High-Risk Alerts
```sql
SELECT * FROM high_risk_alerts ORDER BY risk_score DESC LIMIT 10;
```

### Remediation Success Rates
```sql
SELECT * FROM remediation_summary ORDER BY avg_success_rate DESC;
```

### Daily Summary
```sql
SELECT * FROM daily_syslog_summary 
WHERE analysis_date >= CURRENT_DATE - INTERVAL '7 days';
```

## 🔍 **Monitoring & Analytics**

### Key Metrics
- **Risk Score Distribution**: Monitor severity trends
- **Remediation Success Rate**: Track automation effectiveness  
- **Escalation Frequency**: Measure alert quality
- **MCP Server Performance**: Response times and accuracy
- **Pattern Recognition**: Recurring issues and trends

### Alerting Thresholds
- **Critical Risk Score**: > 8.0 (immediate Slack alert)
- **High Remediation Failure Rate**: < 70% success
- **MCP Server Latency**: > 10 seconds response time
- **Escalation Spike**: > 50% increase in escalations

## 🛠️ **Troubleshooting**

### Common Issues

1. **MCP Server Timeout**
   - Check MCP server availability
   - Verify network connectivity
   - Review MCP server logs

2. **Database Connection Errors**
   - Verify PostgreSQL credentials
   - Check database server status
   - Review table schemas

3. **Slack Notifications Not Sent**
   - Verify webhook URL configuration
   - Check Slack workspace permissions
   - Test webhook endpoint manually

4. **Auto-Remediation Not Triggering**
   - Review remediation eligibility criteria
   - Check MCP response format
   - Verify automation flags in recommendations

### Debug Mode
Enable debug logging by adding this to workflow settings:
```json
{
  "settings": {
    "saveManualExecutions": true,
    "executionOrder": "v1",
    "saveExecutionProgress": true
  }
}
```

## 🔒 **Security Considerations**

- **API Token Security**: Store MCP API tokens securely in n8n credentials
- **Network Security**: Use HTTPS for MCP server communication
- **Access Control**: Restrict webhook endpoint access
- **Audit Trail**: All actions logged in database
- **Remediation Safety**: Rollback plans required for automated actions

## 📈 **Scaling Considerations**

- **Message Volume**: Consider rate limiting for high-volume environments
- **Database Performance**: Monitor database size and query performance
- **MCP Server Capacity**: Scale MCP server based on analysis load
- **Queue Management**: Implement queuing for burst traffic

---

**Last Updated**: August 11, 2025  
**Version**: 1.0.0  
**Workflow ID**: `syslog-mcp-analysis`
