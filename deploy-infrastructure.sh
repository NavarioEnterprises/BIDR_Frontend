#!/bin/bash

# BIDR Infrastructure Deployment Script
# This script deploys the complete BIDR backend infrastructure to Azure using Terraform

set -e  # Exit on any error

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

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Azure CLI is installed
    if ! command_exists az; then
        print_error "Azure CLI is not installed. Please install it from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command_exists terraform; then
        print_error "Terraform is not installed. Please install it from https://www.terraform.io/downloads.html"
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command_exists kubectl; then
        print_warning "kubectl is not installed. You'll need it to interact with the AKS cluster later."
        print_warning "Install from: https://kubernetes.io/docs/tasks/tools/"
    fi
    
    print_success "Prerequisites check completed"
}

# Function to check Azure login status
check_azure_login() {
    print_status "Checking Azure login status..."
    
    if ! az account show >/dev/null 2>&1; then
        print_warning "Not logged into Azure. Starting interactive login..."
        az login
    fi
    
    # Show current subscription
    SUBSCRIPTION=$(az account show --query "name" -o tsv)
    SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)
    print_success "Logged into Azure subscription: $SUBSCRIPTION ($SUBSCRIPTION_ID)"
}

# Function to register required Azure resource providers
register_providers() {
    print_status "Registering required Azure resource providers..."
    
    PROVIDERS=(
        "Microsoft.ContainerRegistry"
        "Microsoft.ContainerService" 
        "Microsoft.Compute"
        "Microsoft.Network"
        "Microsoft.KeyVault"
        "Microsoft.DBforPostgreSQL"
        "Microsoft.Cache"
        "Microsoft.Storage"
        "Microsoft.OperationalInsights"
        "Microsoft.Insights"
    )
    
    for provider in "${PROVIDERS[@]}"; do
        print_status "Registering provider: $provider"
        az provider register --namespace "$provider" --wait
    done
    
    print_success "All resource providers registered successfully"
}

# Function to initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    
    cd terraform
    terraform init -upgrade
    
    print_success "Terraform initialized successfully"
}

# Function to validate Terraform configuration
validate_terraform() {
    print_status "Validating Terraform configuration..."
    
    terraform validate
    terraform fmt -check=true
    
    print_success "Terraform configuration is valid"
}

# Function to plan Terraform deployment
plan_terraform() {
    local env=$1
    local tfvars_file="$env.tfvars"
    
    print_status "Creating Terraform execution plan for $env environment..."
    
    if [[ ! -f "$tfvars_file" ]]; then
        print_error "Terraform variables file $tfvars_file not found"
        exit 1
    fi
    
    terraform plan -var-file="$tfvars_file" -out="$env.tfplan"
    
    print_success "Terraform plan created successfully"
}

# Function to apply Terraform configuration
apply_terraform() {
    local env=$1
    
    print_status "Applying Terraform configuration for $env environment..."
    print_warning "This will create real Azure resources and may incur costs."
    
    # Ask for confirmation
    read -p "Do you want to proceed with the deployment? (yes/no): " confirm
    if [[ $confirm != "yes" ]]; then
        print_warning "Deployment cancelled by user"
        exit 0
    fi
    
    terraform apply "$env.tfplan"
    
    print_success "Infrastructure deployed successfully!"
}

# Function to get deployment outputs
show_outputs() {
    print_status "Retrieving deployment outputs..."
    
    echo ""
    print_status "=== DEPLOYMENT OUTPUTS ==="
    terraform output
    echo ""
    
    # Get specific outputs for setup
    RESOURCE_GROUP=$(terraform output -raw resource_group_name)
    AKS_CLUSTER=$(terraform output -raw aks_cluster_name)
    ACR_NAME=$(terraform output -raw acr_name)
    KEY_VAULT_NAME=$(terraform output -raw key_vault_name)
    
    print_success "Resource Group: $RESOURCE_GROUP"
    print_success "AKS Cluster: $AKS_CLUSTER"
    print_success "Container Registry: $ACR_NAME"
    print_success "Key Vault: $KEY_VAULT_NAME"
}

# Function to configure kubectl for AKS
configure_kubectl() {
    local env=$1
    
    print_status "Configuring kubectl for AKS access..."
    
    RESOURCE_GROUP=$(terraform output -raw resource_group_name)
    AKS_CLUSTER=$(terraform output -raw aks_cluster_name)
    
    az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" --overwrite-existing
    
    # Test connection
    if kubectl get nodes >/dev/null 2>&1; then
        print_success "kubectl configured successfully. AKS cluster is accessible."
        kubectl get nodes
    else
        print_warning "kubectl configuration completed, but cluster may not be ready yet."
    fi
}

# Function to setup admin credentials
setup_admin_credentials() {
    print_status "Setting up admin credentials..."
    
    KEY_VAULT_NAME=$(terraform output -raw key_vault_name)
    
    print_status "Admin credentials are securely stored in Key Vault: $KEY_VAULT_NAME"
    print_status "Service-specific credentials have been generated for each microservice."
    
    echo ""
    print_status "=== CREDENTIAL SUMMARY ==="
    print_status "• Database credentials: Stored in Key Vault"
    print_status "• Redis credentials: Stored in Key Vault" 
    print_status "• Django secret keys: Generated and stored in Key Vault"
    print_status "• Service admin passwords: Generated for each service"
    print_status "• API keys: Generated for service-to-service communication"
    print_status "• JWT secrets: Generated for each service"
    echo ""
    
    print_success "All credentials have been generated and stored securely in Azure Key Vault"
}

# Function to display next steps
show_next_steps() {
    local env=$1
    
    echo ""
    print_status "=== NEXT STEPS ==="
    echo ""
    print_status "1. Configure Kubernetes deployments:"
    print_status "   - Update k8s/overlays/$env/ with your specific configurations"
    print_status "   - Deploy services: kubectl apply -k k8s/overlays/$env/"
    echo ""
    print_status "2. Access your resources:"
    print_status "   - AKS: Use 'kubectl' commands"
    print_status "   - ACR: Use 'az acr login --name \$(terraform output -raw acr_name)'"
    print_status "   - Key Vault: Use Azure portal or 'az keyvault' commands"
    echo ""
    print_status "3. Monitor your deployment:"
    print_status "   - Check pod status: kubectl get pods --all-namespaces"
    print_status "   - View services: kubectl get services --all-namespaces"
    echo ""
    print_status "4. Setup CI/CD:"
    print_status "   - Configure GitHub secrets for AZURE_CREDENTIALS"
    print_status "   - Push to develop branch to trigger DEV deployment"
    print_status "   - Push to main branch to trigger UAT deployment"
    echo ""
}

# Main deployment function
main() {
    local env=${1:-"dev"}
    
    if [[ "$env" != "dev" && "$env" != "uat" && "$env" != "prod" ]]; then
        print_error "Invalid environment. Use: dev, uat, or prod"
        exit 1
    fi
    
    echo ""
    print_status "🚀 BIDR Infrastructure Deployment Starting..."
    print_status "Environment: $env"
    print_status "Timestamp: $(date)"
    echo ""
    
    # Run all deployment steps
    check_prerequisites
    check_azure_login
    # Skipping register_providers since Terraform now handles this with resource_provider_registrations = "none"
    init_terraform
    validate_terraform
    plan_terraform "$env"
    apply_terraform "$env"
    show_outputs
    configure_kubectl "$env"
    setup_admin_credentials
    show_next_steps "$env"
    
    echo ""
    print_success "🎉 BIDR Infrastructure deployment completed successfully!"
    print_success "Environment: $env"
    print_success "All resources are now available in Azure."
    echo ""
}

# Help function
show_help() {
    echo "BIDR Infrastructure Deployment Script"
    echo ""
    echo "Usage: $0 [ENVIRONMENT]"
    echo ""
    echo "ENVIRONMENT:"
    echo "  dev     Deploy to development environment (default)"
    echo "  uat     Deploy to UAT environment" 
    echo "  prod    Deploy to production environment"
    echo ""
    echo "Examples:"
    echo "  $0           # Deploy to dev environment"
    echo "  $0 dev       # Deploy to dev environment"
    echo "  $0 uat       # Deploy to UAT environment"
    echo "  $0 prod      # Deploy to production environment"
    echo ""
}

# Handle command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
