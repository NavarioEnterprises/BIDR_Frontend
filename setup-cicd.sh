#!/bin/bash

set -e

echo "🚀 Setting up CI/CD for BIDR Backend"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="bidr-k8s"
AKS_CLUSTER="BIDR-aks-cluster"
ACR_NAME="BIDRcontainerregistry"
APP_NAME="bidr-backend-app"

echo -e "${YELLOW}📋 CI/CD Setup Requirements:${NC}"
echo "1. Azure CLI logged in"
echo "2. GitHub repository set up"
echo "3. AKS cluster and ACR already deployed"
echo ""

# Check if Azure CLI is logged in
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ Azure CLI not logged in. Please run 'az login' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Azure CLI is logged in${NC}"

# Create service principal for GitHub Actions
echo -e "${YELLOW}🔐 Creating service principal for GitHub Actions...${NC}"

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"

# Create service principal
SP_JSON=$(az ad sp create-for-rbac --name "$APP_NAME" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth)

echo -e "${GREEN}✅ Service principal created${NC}"

# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)

# Get AKS credentials
echo -e "${YELLOW}🔧 Getting AKS credentials...${NC}"
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --overwrite-existing

# Create GitHub repository secrets instructions
echo -e "${GREEN}🎯 GitHub Repository Setup Instructions:${NC}"
echo ""
echo -e "${YELLOW}1. Go to your GitHub repository settings -> Secrets and variables -> Actions${NC}"
echo ""
echo -e "${YELLOW}2. Add the following secrets:${NC}"
echo ""
echo -e "${GREEN}AZURE_CREDENTIALS${NC} (copy the entire JSON below):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$SP_JSON"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}3. Verify the following environment variables in the workflow:${NC}"
echo "   - RESOURCE_GROUP: $RESOURCE_GROUP"
echo "   - AKS_CLUSTER: $AKS_CLUSTER"
echo "   - ACR_NAME: $ACR_NAME"
echo "   - ACR_LOGIN_SERVER: $ACR_LOGIN_SERVER"
echo ""

echo -e "${GREEN}📁 Files created:${NC}"
echo "   ✅ .github/workflows/deploy.yml - Main CI/CD workflow"
echo ""

echo -e "${YELLOW}🔄 Workflow Features:${NC}"
echo "   • Automated testing on pull requests"
echo "   • Staging deployment on 'develop' branch push"
echo "   • Production deployment on 'main' branch push"
echo "   • Docker image building and pushing to ACR"
echo "   • Kubernetes deployment updates"
echo "   • Rollout status verification"
echo ""

echo -e "${GREEN}🚀 Next Steps:${NC}"
echo "1. Add the AZURE_CREDENTIALS secret to your GitHub repository"
echo "2. Push these changes to your repository"
echo "3. Create a 'develop' branch for staging deployments"
echo "4. Test the pipeline with a pull request"
echo ""

echo -e "${YELLOW}📊 Monitoring Commands:${NC}"
echo "   • Check pods: kubectl get pods -n bidr"
echo "   • Check services: kubectl get services -n bidr"
echo "   • View logs: kubectl logs -f deployment/bidr-app -n bidr"
echo "   • Check rollout: kubectl rollout status deployment/bidr-app -n bidr"
echo ""

echo -e "${GREEN}✅ CI/CD setup completed!${NC}"

# Create a sample GitHub workflow trigger file
echo -e "${YELLOW}💡 Creating sample files for testing:${NC}"

# Create .gitignore if it doesn't exist
if [ ! -f .gitignore ]; then
    cat > .gitignore << EOF
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Django
*.log
local_settings.py
db.sqlite3
db.sqlite3-journal
media/

# Environment variables
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Docker
.dockerignore

# Kubernetes
kubeconfig
EOF
    echo "   ✅ .gitignore created"
fi

echo ""
echo -e "${GREEN}🎉 Ready for CI/CD! Your BIDR backend will now auto-deploy on git push.${NC}"
