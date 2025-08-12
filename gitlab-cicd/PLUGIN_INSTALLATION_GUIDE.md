# 📦 Jenkins Plugin Installation Guide

## 🚀 **Method 1: Using plugins.txt with Docker (Recommended)**

This is the method we just used successfully for your setup:

### **1. Create plugins.txt file**
```txt
# Core Pipeline Functionality
workflow-aggregator
pipeline-stage-view
blueocean
git
docker-workflow
credentials
job-dsl
configuration-as-code
```

### **2. Update Dockerfile**
```dockerfile
# Copy plugin list and install during build
COPY jenkins/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
```

### **3. Build and Run**
```bash
cd /home/dan/POC2/gitlab-cicd
docker compose -f docker-compose.jenkins.yml build --no-cache jenkins
docker compose -f docker-compose.jenkins.yml up -d jenkins
```

## 🔧 **Method 2: Post-Startup Installation**

### **Using Jenkins CLI**
```bash
# Download Jenkins CLI
wget http://localhost:8090/jnlpJars/jenkins-cli.jar

# Install plugins
java -jar jenkins-cli.jar -s http://localhost:8090/ install-plugin workflow-aggregator git docker-workflow
```

### **Using Script Console**
Access Jenkins → Manage Jenkins → Script Console:
```groovy
def pluginManager = Jenkins.instance.pluginManager
def updateCenter = Jenkins.instance.updateCenter

def plugins = [
    "workflow-aggregator",
    "git", 
    "docker-workflow",
    "job-dsl"
]

plugins.each { pluginName ->
    if (!pluginManager.getPlugin(pluginName)) {
        def plugin = updateCenter.getPlugin(pluginName)
        if (plugin) {
            plugin.deploy()
            println "Installing ${pluginName}"
        }
    }
}

Jenkins.instance.restart()
```

## 📋 **Method 3: Web Interface Installation**

1. **Access Jenkins**: http://localhost:8090
2. **Navigate**: Manage Jenkins → Manage Plugins
3. **Available Tab**: Search and select plugins
4. **Install**: Click "Install without restart" or "Download now and install after restart"

## 🛡️ **Method 4: Manual Plugin Installation**

### **Download and Install**
```bash
# Download plugin .hpi files
wget https://updates.jenkins.io/latest/workflow-aggregator.hpi

# Copy to Jenkins plugins directory
docker cp workflow-aggregator.hpi poc2-jenkins-new:/var/jenkins_home/plugins/

# Restart Jenkins
docker restart poc2-jenkins-new
```

## ✅ **Current Status - Your Setup**

Your Jenkins container `poc2-jenkins-new` now has these plugins installed:

### **✅ Core Pipeline**
- workflow-aggregator (Pipeline suite)
- pipeline-stage-view (Visual stages)
- blueocean (Modern UI)
- pipeline-utility-steps (Utility functions)

### **✅ Source Control**
- git (Git integration)
- github (GitHub integration)
- multibranch-scan-webhook-trigger (Webhook support)

### **✅ Docker & Containers**
- docker-workflow (Docker pipeline steps)
- docker-plugin (Docker cloud integration)

### **✅ Security & Credentials**
- credentials (Core credential management)
- credentials-binding (Environment binding)
- ssh-credentials (SSH key management)
- matrix-auth (Role-based security)

### **✅ Build Tools**
- ant (Apache Ant)
- gradle (Gradle builds)
- maven-plugin (Maven integration)
- pipeline-maven (Maven pipelines)

### **✅ Language Support**
- nodejs (Node.js support)
- python (Python support)
- ansible (Ansible automation)

### **✅ Testing & Quality**
- junit (JUnit test results)
- performance (Performance testing)
- htmlpublisher (HTML reports)
- warnings-ng (Static analysis)

### **✅ Notifications**
- email-ext (Extended email)
- slack (Slack integration)
- http_request (HTTP requests)

### **✅ Automation**
- job-dsl (Programmatic job creation)
- configuration-as-code (JCasC)
- parameterized-trigger (Build triggers)

### **✅ Utilities**
- build-timeout (Build timeouts)
- timestamper (Timestamps)
- ws-cleanup (Workspace cleanup)
- copyartifact (Artifact copying)
- lockable-resources (Resource locking)
- build-name-setter (Custom build names)

### **✅ Monitoring**
- prometheus (Metrics collection)
- build-monitor-plugin (Build monitoring)

## 🔍 **Verify Plugin Installation**

### **Check via CLI**
```bash
docker exec poc2-jenkins-new java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/ list-plugins
```

### **Check via Web Interface**
1. Go to: http://localhost:8090
2. Navigate: Manage Jenkins → Manage Plugins → Installed tab
3. Search for specific plugins

### **Check via Script Console**
```groovy
Jenkins.instance.pluginManager.plugins.each { plugin ->
    println "${plugin.shortName}: ${plugin.version}"
}
```

## 🚀 **Next Steps**

1. **Complete Jenkins Setup**: http://localhost:8090
2. **Create Admin User**: Follow the setup wizard
3. **Configure Security**: Set up authentication and authorization
4. **Create Your First Pipeline**: Use the Job DSL or Pipeline scripts
5. **Configure Notifications**: Set up Slack, email, or webhook notifications
6. **Integrate with Your Services**: Connect with NetBox, n8n, and Docker services

## 🎯 **Pro Tips**

### **Plugin Management Best Practices**
- Always backup Jenkins before installing new plugins
- Test plugin combinations in a staging environment
- Keep plugins updated for security patches
- Remove unused plugins to reduce attack surface
- Use specific plugin versions in production

### **Troubleshooting**
- Check Jenkins logs: `docker logs poc2-jenkins-new`
- Verify plugin compatibility with Jenkins version
- Clear browser cache if UI issues occur
- Restart Jenkins after major plugin installations

---

**🎉 Your Jenkins is now fully equipped with enterprise-grade plugins and ready for production use!**

**Access Jenkins**: http://localhost:8090  
**Container**: `poc2-jenkins-new`  
**Status**: ✅ **READY WITH ALL PLUGINS INSTALLED**
