#!/bin/bash

# Script to install and configure kubectl on macOS
echo "🔧 Installing kubectl on macOS..."
echo "=================================="

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew first..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for current session
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "✅ Homebrew is available"

# Install kubectl
echo "📥 Installing kubectl..."
brew install kubectl

# Verify installation
if command -v kubectl &> /dev/null; then
    echo "✅ kubectl installed successfully!"
    echo "📋 Version: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
    echo "❌ kubectl installation failed"
    exit 1
fi

echo ""
echo "🔑 Next steps to connect to your Azure Kubernetes cluster:"
echo "=========================================================="
echo ""
echo "1. Install Azure CLI (if not already installed):"
echo "   brew install azure-cli"
echo ""
echo "2. Login to Azure:"
echo "   az login"
echo ""
echo "3. Get AKS credentials (replace with your actual values):"
echo "   az aks get-credentials --resource-group YOUR_RESOURCE_GROUP --name YOUR_CLUSTER_NAME"
echo ""
echo "4. Test connection:"
echo "   kubectl cluster-info"
echo "   kubectl get nodes"
echo ""
echo "5. Check if you can see your BIDR services:"
echo "   kubectl get pods -n bidr"
echo ""
echo "📝 If you need help finding your cluster details:"
echo "   az aks list --output table"
echo ""
echo "Once kubectl is configured, you can run the deployment script again:"
echo "   python deploy_to_k8s.py"