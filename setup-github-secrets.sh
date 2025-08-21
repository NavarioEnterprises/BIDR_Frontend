#!/bin/bash

# BIDR GitHub Actions Setup Script
# This script helps you get the credentials needed for GitHub Actions

set -e

echo "🚀 BIDR GitHub Actions Setup"
echo "================================"

# Check if user is logged in to Azure
if ! az account show &> /dev/null; then
    echo "❌ Please login to Azure first: az login"
    exit 1
fi

# Get subscription info
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

echo "📋 Current Azure Subscription:"
echo "   Name: $SUBSCRIPTION_NAME"
echo "   ID: $SUBSCRIPTION_ID"
echo ""

# Resource group and cluster info
RESOURCE_GROUP="bidr-dev-k8s"
CLUSTER_NAME="BIDR-dev-aks-cluster"
ACR_NAME="bidrnparusdevregistry2024"

echo "🏗️  BIDR Resources:"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   AKS Cluster: $CLUSTER_NAME"
echo "   Container Registry: $ACR_NAME"
echo ""

# Create service principal
echo "🔐 Creating Service Principal..."
SP_NAME="BIDR-GitHub-Actions-$(date +%s)"

# Create the service principal with contributor role on the resource group
SP_OUTPUT=$(az ad sp create-for-rbac --name "$SP_NAME" \
  --role contributor \
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
  --sdk-auth)

# Extract values
CLIENT_ID=$(echo $SP_OUTPUT | jq -r '.clientId')
CLIENT_SECRET=$(echo $SP_OUTPUT | jq -r '.clientSecret')
TENANT_ID=$(echo $SP_OUTPUT | jq -r '.tenantId')

echo "✅ Service Principal created: $SP_NAME"

# Grant additional permissions
echo "🔑 Granting AKS permissions..."
az role assignment create \
  --assignee "$CLIENT_ID" \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$CLUSTER_NAME" \
  &> /dev/null

echo "🐳 Granting ACR permissions..."
az role assignment create \
  --assignee "$CLIENT_ID" \
  --role "AcrPush" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME" \
  &> /dev/null

# Get ACR credentials
echo "📦 Getting ACR credentials..."
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv)

echo "✅ All permissions granted!"
echo ""

# Display the secrets to add to GitHub
echo "🔒 ADD THESE SECRETS TO YOUR GITHUB REPOSITORY:"
echo "=============================================="
echo ""
echo "Go to: GitHub Repo → Settings → Secrets and Variables → Actions → New repository secret"
echo ""

echo "1. AZURE_CREDENTIALS:"
echo "   Name: AZURE_CREDENTIALS"
echo "   Value:"
cat << EOF
{
  "clientId": "$CLIENT_ID",
  "clientSecret": "$CLIENT_SECRET",
  "subscriptionId": "$SUBSCRIPTION_ID",
  "tenantId": "$TENANT_ID"
}
EOF
echo ""

echo "2. ACR_USERNAME:"
echo "   Name: ACR_USERNAME"
echo "   Value: $ACR_USERNAME"
echo ""

echo "3. ACR_PASSWORD:"
echo "   Name: ACR_PASSWORD" 
echo "   Value: $ACR_PASSWORD"
echo ""

echo "🎯 NEXT STEPS:"
echo "=============="
echo "1. Add the above 3 secrets to your GitHub repository"
echo "2. Push your code to the main branch"
echo "3. Watch the GitHub Actions deploy your app automatically!"
echo "4. Access your app at: http://4.221.172.198/"
echo ""
echo "📊 To monitor your deployment:"
echo "   - GitHub Actions: https://github.com/YOUR_USERNAME/YOUR_REPO/actions"
echo "   - AKS Pods: kubectl get pods -n bidr"
echo "   - Service Health: curl http://4.221.172.198/health"
echo ""

# Save to file for reference
SECRETS_FILE="github-secrets-$(date +%Y%m%d-%H%M%S).txt"
cat << EOF > $SECRETS_FILE
BIDR GitHub Secrets - Generated $(date)
=====================================

AZURE_CREDENTIALS:
{
  "clientId": "$CLIENT_ID",
  "clientSecret": "$CLIENT_SECRET", 
  "subscriptionId": "$SUBSCRIPTION_ID",
  "tenantId": "$TENANT_ID"
}

ACR_USERNAME: $ACR_USERNAME
ACR_PASSWORD: $ACR_PASSWORD

Service Principal: $SP_NAME
EOF

echo "💾 Secrets also saved to: $SECRETS_FILE"
echo "⚠️  Keep this file secure and delete it after adding secrets to GitHub!"
echo ""
echo "🚀 Your BIDR CI/CD is ready to go!"
