# 🔧 Quick Environment Variables Update

# Replace YOUR_NETBOX_TOKEN_HERE with your actual NetBox API token

# Step 1: Edit docker-compose.yml
# Find this line:
#   - NETBOX_TOKEN=change-me-to-your-netbox-token
# Replace with:
#   - NETBOX_TOKEN=YOUR_ACTUAL_TOKEN_HERE

# Step 2: Restart n8n
docker compose restart n8n-network-automation

# Step 3: Import quick-start workflow
# Go to: http://localhost:5678
# Import file: /home/dan/POC2/n8n/workflows/templates/quick-start-ai-network.json

# Step 4: Test the workflow
# The workflow will use these environment variables automatically:
# - $env.NETBOX_URL (http://localhost:8000)
# - $env.NETBOX_TOKEN (your token)
# - $env.CUSTOMER_ID (demo-corp)

echo "✅ Environment variables are now configured in docker-compose.yml"
echo "🔄 Just update the NETBOX_TOKEN value with your actual token"
