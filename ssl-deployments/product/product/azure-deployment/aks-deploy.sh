#!/bin/bash

# Azure Kubernetes Service Deployment Script
# This script deploys the BIDR Product Management Service to AKS for enterprise-grade hosting

set -e

# Configuration variables - UPDATE THESE
RESOURCE_GROUP="bidr-aks-rg"
CLUSTER_NAME="bidr-aks-cluster"
CONTAINER_REGISTRY="bidrregistry"
LOCATION="eastus"
NODE_COUNT=3
VM_SIZE="Standard_D2s_v3"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Azure Kubernetes Service deployment...${NC}"

# Step 1: Create Resource Group
echo -e "${YELLOW}Creating resource group...${NC}"
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION

# Step 2: Create Azure Container Registry
echo -e "${YELLOW}Creating Azure Container Registry...${NC}"
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_REGISTRY \
    --sku Standard \
    --admin-enabled true

# Step 3: Build and push Docker image
echo -e "${YELLOW}Building and pushing Docker image...${NC}"
ACR_LOGIN_SERVER=$(az acr show --name $CONTAINER_REGISTRY --resource-group $RESOURCE_GROUP --query "loginServer" --output tsv)
az acr build \
    --registry $CONTAINER_REGISTRY \
    --image bidr-product-management:latest \
    .

# Step 4: Create AKS cluster
echo -e "${YELLOW}Creating AKS cluster (this may take 5-10 minutes)...${NC}"
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --node-count $NODE_COUNT \
    --node-vm-size $VM_SIZE \
    --location $LOCATION \
    --attach-acr $CONTAINER_REGISTRY \
    --generate-ssh-keys \
    --enable-managed-identity

# Step 5: Get AKS credentials
echo -e "${YELLOW}Getting AKS credentials...${NC}"
az aks get-credentials \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --overwrite-existing

# Step 6: Update the deployment YAML with correct ACR name
echo -e "${YELLOW}Updating deployment configuration...${NC}"
sed -i.bak "s/bidrregistry.azurecr.io/$ACR_LOGIN_SERVER/g" azure-deployment/aks-deployment.yaml

# Step 7: Generate a new secret key
SECRET_KEY=$(openssl rand -base64 32)
SECRET_KEY_B64=$(echo -n $SECRET_KEY | base64)
sed -i.bak "s/eW91ci1zZWNyZXQta2V5LWhlcmUtY2hhbmdlLW1l/$SECRET_KEY_B64/g" azure-deployment/aks-deployment.yaml

# Step 8: Deploy to AKS
echo -e "${YELLOW}Deploying application to AKS...${NC}"
kubectl apply -f azure-deployment/aks-deployment.yaml

# Step 9: Wait for deployment to be ready
echo -e "${YELLOW}Waiting for deployment to be ready...${NC}"
kubectl rollout status deployment/bidr-product-management

# Step 10: Get service external IP
echo -e "${YELLOW}Waiting for LoadBalancer to assign external IP...${NC}"
echo "This may take a few minutes..."

# Wait for external IP
EXTERNAL_IP=""
while [ -z $EXTERNAL_IP ]; do
  echo "Waiting for external IP..."
  EXTERNAL_IP=$(kubectl get service bidr-product-management-service --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
  [ -z "$EXTERNAL_IP" ] && sleep 10
done

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}External IP: $EXTERNAL_IP${NC}"
echo -e "${GREEN}Admin URL: http://$EXTERNAL_IP/admin/${NC}"
echo -e "${GREEN}API URL: http://$EXTERNAL_IP/api/${NC}"
echo -e "${GREEN}Health Check: http://$EXTERNAL_IP/health/${NC}"
echo -e "${GREEN}========================================${NC}"

# Step 11: Show useful kubectl commands
echo -e "${YELLOW}Useful commands:${NC}"
echo -e "${GREEN}Check pod status: kubectl get pods${NC}"
echo -e "${GREEN}Check service status: kubectl get services${NC}"
echo -e "${GREEN}View logs: kubectl logs -l app=bidr-product-management${NC}"
echo -e "${GREEN}Scale deployment: kubectl scale deployment bidr-product-management --replicas=5${NC}"

# Step 12: Run database migrations
echo -e "${YELLOW}Running database migrations...${NC}"
POD_NAME=$(kubectl get pods -l app=bidr-product-management -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- python product_management_service/manage.py migrate

echo -e "${GREEN}AKS deployment completed!${NC}"
