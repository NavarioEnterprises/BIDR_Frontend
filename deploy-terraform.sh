#!/bin/bash

# BIDR Terraform Deployment Script
# This script deploys the BIDR infrastructure using Terraform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install Terraform first."
    print_status "Visit: https://terraform.io/downloads.html"
    exit 1
fi

# Check if Azure CLI is installed and logged in
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install Azure CLI first."
    print_status "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check Azure login status
if ! az account show &> /dev/null; then
    print_error "Please login to Azure first: az login"
    exit 1
fi

# Change to terraform directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/terraform"

if [ ! -d "$TERRAFORM_DIR" ]; then
    print_error "Terraform directory not found: $TERRAFORM_DIR"
    exit 1
fi

cd "$TERRAFORM_DIR"

print_status "🚀 Starting BIDR Terraform deployment..."
print_status "Working directory: $(pwd)"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    print_warning "terraform.tfvars not found. Creating from example..."
    if [ -f "terraform.tfvars.example" ]; then
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your specific values before continuing."
        print_status "Key variables to update:"
        print_status "  - key_vault_name (must be globally unique)"
        print_status "  - email_host_user (if using email notifications)"
        print_status "  - email_host_password (if using email notifications)"
        read -p "Press Enter to continue after editing terraform.tfvars..."
    else
        print_error "terraform.tfvars.example not found"
        exit 1
    fi
fi

# Initialize Terraform
print_status "📋 Initializing Terraform..."
if terraform init; then
    print_success "Terraform initialized successfully"
else
    print_error "Failed to initialize Terraform"
    exit 1
fi

# Validate Terraform configuration
print_status "✅ Validating Terraform configuration..."
if terraform validate; then
    print_success "Terraform configuration is valid"
else
    print_error "Terraform configuration validation failed"
    exit 1
fi

# Plan Terraform deployment
print_status "📝 Creating Terraform execution plan..."
if terraform plan -out=tfplan; then
    print_success "Terraform plan created successfully"
else
    print_error "Failed to create Terraform plan"
    exit 1
fi

# Ask for confirmation before applying
print_warning "⚠️  This will create Azure resources which may incur costs."
read -p "Do you want to proceed with the deployment? (yes/no): " confirm

if [[ $confirm != "yes" ]]; then
    print_status "Deployment cancelled by user"
    exit 0
fi

# Apply Terraform configuration
print_status "🏗️  Applying Terraform configuration..."
if terraform apply tfplan; then
    print_success "Terraform deployment completed successfully!"
else
    print_error "Terraform deployment failed"
    exit 1
fi

# Display outputs
print_status "📊 Deployment outputs:"
terraform output

# Save kubeconfig
print_status "⚙️  Configuring kubectl..."
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
AKS_CLUSTER=$(terraform output -raw aks_cluster_name)

if az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" --overwrite-existing; then
    print_success "kubectl configured successfully"
else
    print_warning "Failed to configure kubectl. You can configure it manually later."
fi

# Display next steps
print_success "🎉 BIDR infrastructure deployment completed!"
print_status ""
print_status "Next steps:"
print_status "1. Update your CI/CD pipeline with the new resource names"
print_status "2. Deploy your Kubernetes manifests: kubectl apply -k ../k8s/"
print_status "3. Check the deployment status: kubectl get pods -n bidr"
print_status ""
print_status "Useful commands:"
print_status "  - Login to ACR: $(terraform output -raw acr_login_command)"
print_status "  - Configure kubectl: $(terraform output -raw kubectl_config_command)"
print_status "  - Access Key Vault: az keyvault secret list --vault-name $(terraform output -raw key_vault_name)"

# Clean up plan file
rm -f tfplan

print_success "Deployment script completed successfully! 🎉"
