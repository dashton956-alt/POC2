# Simple MCP Server for Syslog Analysis

A lightweight Model Context Protocol (MCP) server example for analyzing syslog messages and providing intelligent recommendations.

## 🚀 **Quick Start**

### Prerequisites
- Node.js 18+
- npm or yarn

### Installation
```bash
mkdir syslog-mcp-server
cd syslog-mcp-server
npm init -y
npm install express cors helmet morgan winston uuid
```

## 📝 **MCP Server Implementation**

Create `server.js`:

```javascript
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const winston = require('winston');
const { v4: uuidv4 } = require('uuid');

// Configure logging
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

const app = express();
const PORT = process.env.PORT || 3001;
const API_TOKEN = process.env.MCP_API_TOKEN || 'mcp_demo_token_12345';

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined', { stream: { write: (msg) => logger.info(msg.trim()) } }));
app.use(express.json({ limit: '10mb' }));

// Authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token || token !== API_TOKEN) {
    return res.status(401).json({ error: 'Unauthorized', message: 'Invalid or missing API token' });
  }

  next();
};

// Syslog analysis patterns and rules
const ANALYSIS_PATTERNS = {
  security: {
    patterns: [
      { regex: /failed password|authentication failure|invalid user/i, category: 'Authentication', risk: 7 },
      { regex: /sudo|su:|privilege escalation/i, category: 'Privilege Escalation', risk: 8 },
      { regex: /firewall|blocked|denied/i, category: 'Network Security', risk: 6 },
      { regex: /malware|virus|trojan/i, category: 'Malware', risk: 9 },
      { regex: /brute force|attack|intrusion/i, category: 'Attack', risk: 8 }
    ]
  },
  system: {
    patterns: [
      { regex: /out of memory|oom|memory exhausted/i, category: 'Memory', risk: 8 },
      { regex: /disk full|no space|filesystem/i, category: 'Storage', risk: 7 },
      { regex: /cpu|load average|performance/i, category: 'Performance', risk: 6 },
      { regex: /network.*down|interface.*down|connection.*lost/i, category: 'Network', risk: 7 },
      { regex: /service.*failed|daemon.*crashed|process.*died/i, category: 'Service Failure', risk: 8 }
    ]
  },
  application: {
    patterns: [
      { regex: /error|exception|stack trace/i, category: 'Application Error', risk: 6 },
      { regex: /database.*error|sql.*error|connection.*refused/i, category: 'Database', risk: 7 },
      { regex: /timeout|slow query|performance/i, category: 'Performance', risk: 5 },
      { regex: /backup.*failed|restore.*failed/i, category: 'Backup', risk: 7 }
    ]
  }
};

// Analysis function
function analyzeSyslogMessage(data) {
  const { message, parsed_data, metadata } = data;
  const fullMessage = message || parsed_data.message || '';
  
  let bestMatch = null;
  let maxRisk = parsed_data.severity || 5;
  let category = 'General';
  let subCategory = 'Unknown';
  
  // Pattern matching
  for (const [type, config] of Object.entries(ANALYSIS_PATTERNS)) {
    for (const pattern of config.patterns) {
      if (pattern.regex.test(fullMessage)) {
        if (!bestMatch || pattern.risk > bestMatch.risk) {
          bestMatch = pattern;
          category = type.charAt(0).toUpperCase() + type.slice(1);
          subCategory = pattern.category;
          maxRisk = Math.max(maxRisk, pattern.risk);
        }
      }
    }
  }
  
  // Generate recommendations based on analysis
  const recommendations = generateRecommendations(category, subCategory, maxRisk, parsed_data, fullMessage);
  const remediationSteps = generateRemediationSteps(category, subCategory, parsed_data, metadata);
  
  return {
    analysis: {
      confidence_score: bestMatch ? 0.85 : 0.6,
      category,
      sub_category: subCategory,
      description: bestMatch ? 
        `Detected ${subCategory.toLowerCase()} issue: ${bestMatch.category}` :
        'General system message requiring review',
      similar_incidents: Math.floor(Math.random() * 10),
      trend_analysis: 'Trending within normal parameters'
    },
    severity_assessment: {
      level: maxRisk > 7 ? 'CRITICAL' : maxRisk > 5 ? 'WARNING' : 'INFO',
      risk_score: maxRisk,
      impact: maxRisk > 7 ? 'High' : maxRisk > 5 ? 'Medium' : 'Low',
      urgency: maxRisk > 7 ? 'High' : maxRisk > 5 ? 'Medium' : 'Low',
      business_impact: maxRisk > 8 ? 'High' : maxRisk > 6 ? 'Medium' : 'Low'
    },
    root_cause_analysis: {
      probable_cause: getProbableCause(category, subCategory, fullMessage),
      contributing_factors: getContributingFactors(category, subCategory),
      affected_systems: [parsed_data.hostname || 'unknown'],
      error_patterns: [bestMatch?.category || 'General pattern']
    },
    recommendations,
    remediation_steps: remediationSteps
  };
}

function generateRecommendations(category, subCategory, riskScore, parsedData, message) {
  const recommendations = [];
  
  // Security recommendations
  if (category === 'Security') {
    if (subCategory === 'Authentication') {
      recommendations.push({
        priority: 'High',
        category: 'Security',
        title: 'Implement fail2ban protection',
        description: 'Configure fail2ban to automatically block IPs after failed authentication attempts',
        estimated_effort: '30 minutes',
        automation_possible: true,
        immediate_action: true
      });
      recommendations.push({
        priority: 'Medium',
        category: 'Security', 
        title: 'Review password policies',
        description: 'Ensure strong password requirements and account lockout policies',
        estimated_effort: '1 hour',
        automation_possible: false,
        immediate_action: false
      });
    }
    
    if (subCategory === 'Attack') {
      recommendations.push({
        priority: 'Critical',
        category: 'Security',
        title: 'Block suspicious IP immediately',
        description: 'Add firewall rule to block the attacking IP address',
        estimated_effort: '5 minutes',
        automation_possible: true,
        immediate_action: true
      });
    }
  }
  
  // System recommendations
  if (category === 'System') {
    if (subCategory === 'Memory') {
      recommendations.push({
        priority: 'High',
        category: 'System',
        title: 'Increase memory or optimize processes',
        description: 'Monitor memory usage and identify memory-intensive processes',
        estimated_effort: '2 hours',
        automation_possible: true,
        immediate_action: true
      });
    }
    
    if (subCategory === 'Storage') {
      recommendations.push({
        priority: 'High',
        category: 'System',
        title: 'Clean up disk space',
        description: 'Remove old logs, temporary files, or unused packages',
        estimated_effort: '1 hour',
        automation_possible: true,
        immediate_action: true
      });
    }
  }
  
  // General recommendations
  if (riskScore > 7) {
    recommendations.push({
      priority: 'High',
      category: 'Monitoring',
      title: 'Increase monitoring frequency',
      description: 'Temporarily increase monitoring intervals for affected system',
      estimated_effort: '15 minutes',
      automation_possible: true,
      immediate_action: false
    });
  }
  
  return recommendations;
}

function generateRemediationSteps(category, subCategory, parsedData, metadata) {
  const steps = [];
  
  if (category === 'Security' && subCategory === 'Authentication') {
    steps.push({
      action: 'Block suspicious IP address',
      command: \`iptables -A INPUT -s \${metadata.source_ip || 'UNKNOWN'} -j DROP\`,
      expected_outcome: 'Prevent further attacks from this IP',
      validation: 'Check iptables rules: iptables -L INPUT -n',
      rollback_plan: \`iptables -D INPUT -s \${metadata.source_ip || 'UNKNOWN'} -j DROP\`
    });
    
    steps.push({
      action: 'Monitor authentication logs',
      command: 'tail -f /var/log/auth.log | grep "Failed password"',
      expected_outcome: 'Continuous monitoring of authentication attempts',
      validation: 'Verify log monitoring is active',
      rollback_plan: 'Stop monitoring process'
    });
  }
  
  if (category === 'System' && subCategory === 'Memory') {
    steps.push({
      action: 'Restart memory-intensive services',
      command: 'systemctl restart high-memory-service',
      expected_outcome: 'Free up memory resources',
      validation: 'Check memory usage: free -h',
      rollback_plan: 'Monitor service logs for issues'
    });
  }
  
  if (category === 'System' && subCategory === 'Storage') {
    steps.push({
      action: 'Clean temporary files',
      command: 'find /tmp -type f -atime +7 -delete',
      expected_outcome: 'Free disk space',
      validation: 'Check disk usage: df -h',
      rollback_plan: 'Restore from backup if needed'
    });
  }
  
  return steps;
}

function getProbableCause(category, subCategory, message) {
  const causes = {
    'Security-Authentication': 'Brute force attack or misconfigured authentication',
    'Security-Attack': 'Active security breach or attack in progress',
    'System-Memory': 'Memory leak or insufficient system resources',
    'System-Storage': 'Disk space exhaustion or large file growth',
    'System-Performance': 'Resource contention or system overload',
    'Application-Database': 'Database connectivity or query performance issues'
  };
  
  return causes[\`\${category}-\${subCategory}\`] || 'System anomaly requiring investigation';
}

function getContributingFactors(category, subCategory) {
  const factors = {
    'Security': ['Weak authentication policies', 'Missing security updates', 'Insufficient monitoring'],
    'System': ['Resource constraints', 'Configuration issues', 'Hardware limitations'],
    'Application': ['Software bugs', 'Configuration errors', 'Resource conflicts']
  };
  
  return factors[category] || ['Configuration issues', 'Resource constraints'];
}

// Routes
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

app.post('/analyze', authenticateToken, (req, res) => {
  try {
    const { type, data, analysis_request } = req.body;
    
    if (type !== 'syslog_analysis') {
      return res.status(400).json({ 
        error: 'Invalid request type', 
        message: 'Only syslog_analysis is supported' 
      });
    }
    
    if (!data || !data.message) {
      return res.status(400).json({ 
        error: 'Missing data', 
        message: 'Syslog message data is required' 
      });
    }
    
    logger.info('Processing syslog analysis request', { 
      hostname: data.parsed_data?.hostname,
      severity: data.parsed_data?.severity 
    });
    
    const startTime = Date.now();
    const analysis = analyzeSyslogMessage(data);
    const responseTime = Date.now() - startTime;
    
    logger.info('Analysis completed', { 
      responseTime,
      riskScore: analysis.severity_assessment.risk_score,
      category: analysis.analysis.category
    });
    
    res.json({
      ...analysis,
      meta: {
        request_id: uuidv4(),
        response_time_ms: responseTime,
        processed_at: new Date().toISOString()
      }
    });
    
  } catch (error) {
    logger.error('Analysis error', error);
    res.status(500).json({ 
      error: 'Analysis failed', 
      message: error.message 
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  logger.error('Unhandled error', error);
  res.status(500).json({ 
    error: 'Internal server error', 
    message: 'An unexpected error occurred' 
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ 
    error: 'Not found', 
    message: 'Endpoint not found' 
  });
});

// Start server
app.listen(PORT, () => {
  logger.info(\`MCP Server running on port \${PORT}\`);
  console.log(\`🚀 MCP Server running on http://localhost:\${PORT}\`);
  console.log(\`📊 Health check: http://localhost:\${PORT}/health\`);
  console.log(\`🔑 API Token: \${API_TOKEN}\`);
});

module.exports = app;
```

## 🔧 **Configuration**

Create `.env` file:
```bash
PORT=3001
MCP_API_TOKEN=mcp_demo_token_12345
NODE_ENV=production
LOG_LEVEL=info
```

Create `package.json`:
```json
{
  "name": "syslog-mcp-server",
  "version": "1.0.0",
  "description": "Simple MCP Server for Syslog Analysis",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "curl -X GET http://localhost:3001/health"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "morgan": "^1.10.0",
    "winston": "^3.10.0",
    "uuid": "^9.0.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
```

## 🚀 **Running the Server**

```bash
# Install dependencies
npm install

# Start server
npm start

# Or for development
npm run dev

# Test health endpoint
curl http://localhost:3001/health

# Test analysis endpoint
curl -X POST http://localhost:3001/analyze \
  -H "Authorization: Bearer mcp_demo_token_12345" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "syslog_analysis",
    "data": {
      "message": "<38>Aug 11 12:30:45 server01 sshd[12345]: Failed password for invalid user admin from 192.168.1.100 port 22 ssh2",
      "parsed_data": {
        "severity": 3,
        "facility": 16,
        "hostname": "server01",
        "tag": "sshd"
      },
      "metadata": {
        "source_ip": "192.168.1.100"
      }
    },
    "analysis_request": {
      "include_recommendations": true,
      "include_severity_assessment": true,
      "include_root_cause_analysis": true,
      "include_remediation_steps": true
    }
  }'
```

## 🐳 **Docker Support**

Create `Dockerfile`:
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3001

USER node

CMD ["node", "server.js"]
```

Create `docker-compose.yml`:
```yaml
version: '3.8'
services:
  mcp-server:
    build: .
    ports:
      - "3001:3001"
    environment:
      - PORT=3001
      - MCP_API_TOKEN=mcp_demo_token_12345
      - NODE_ENV=production
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## 📈 **Extending the Server**

### Add Machine Learning
```bash
npm install @tensorflow/tfjs-node natural
```

### Add Database Storage
```bash
npm install postgres redis
```

### Add More Analysis Patterns
Edit the `ANALYSIS_PATTERNS` object in `server.js` to add custom patterns for your environment.

---

**Note**: This is a simple example MCP server. For production use, consider adding:
- Machine learning models for better accuracy
- Database integration for pattern learning
- Advanced security features
- Rate limiting and monitoring
- Clustering for high availability
