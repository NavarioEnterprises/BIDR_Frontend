#!/bin/bash

# BIDR Admin Credentials Retrieval Script
# Retrieves and displays admin credentials from Azure Key Vault

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Function to get Key Vault name from Terraform output
get_keyvault_name() {
    local env=${1:-"dev"}
    
    if [[ -d "terraform" ]]; then
        cd terraform
        if terraform show >/dev/null 2>&1; then
            KEY_VAULT_NAME=$(terraform output -raw key_vault_name 2>/dev/null)
            if [[ -n "$KEY_VAULT_NAME" ]]; then
                echo "$KEY_VAULT_NAME"
                return 0
            fi
        fi
        cd ..
    fi
    
    # Fallback to naming convention
    case "$env" in
        "dev")
            echo "bidr-nparus-dev-vault-2024"
            ;;
        "uat")
            echo "bidr-nparus-uat-vault-2024"
            ;;
        "prod")
            echo "bidr-nparus-vault-2024"
            ;;
        *)
            echo "bidr-nparus-dev-vault-2024"
            ;;
    esac
}

# Function to retrieve and display credentials
show_credentials() {
    local env=${1:-"dev"}
    local key_vault_name=$(get_keyvault_name "$env")
    
    print_status "Retrieving admin credentials from Key Vault: $key_vault_name"
    print_status "Environment: $env"
    echo ""
    
    # Check if logged into Azure
    if ! az account show >/dev/null 2>&1; then
        print_error "Not logged into Azure. Please run 'az login' first."
        exit 1
    fi
    
    # Check if Key Vault exists and is accessible
    if ! az keyvault show --name "$key_vault_name" >/dev/null 2>&1; then
        print_error "Key Vault '$key_vault_name' not found or not accessible."
        print_error "Make sure you have deployed the infrastructure and have proper permissions."
        exit 1
    fi
    
    print_success "=== BIDR ADMIN CREDENTIALS ==="
    echo ""
    
    # Global admin credentials
    print_status "🔑 GLOBAL ADMIN CREDENTIALS:"
    ADMIN_PASSWORD=$(az keyvault secret show --vault-name "$key_vault_name" --name "admin-password" --query "value" -o tsv 2>/dev/null || echo "N/A")
    echo "   Username: admin"
    echo "   Email: admin@bidr.local"
    echo "   Password: $ADMIN_PASSWORD"
    echo ""
    
    # Service-specific admin passwords
    print_status "🔧 SERVICE-SPECIFIC ADMIN PASSWORDS:"
    SERVICES=("auth" "chat" "payment" "resolution" "product" "notifications" "transactions" "reviews")
    
    for service in "${SERVICES[@]}"; do
        SERVICE_PASSWORD=$(az keyvault secret show --vault-name "$key_vault_name" --name "${service}-service-admin-password" --query "value" -o tsv 2>/dev/null || echo "N/A")
        echo "   ${service^} Service Admin: $SERVICE_PASSWORD"
    done
    echo ""
    
    # Database credentials
    print_status "💾 DATABASE CREDENTIALS:"
    DB_USER=$(az keyvault secret show --vault-name "$key_vault_name" --name "database-user" --query "value" -o tsv 2>/dev/null || echo "N/A")
    DB_PASSWORD=$(az keyvault secret show --vault-name "$key_vault_name" --name "database-password" --query "value" -o tsv 2>/dev/null || echo "N/A")
    echo "   Database User: $DB_USER"
    echo "   Database Password: $DB_PASSWORD"
    echo ""
    
    # Redis credentials
    print_status "🗄️ REDIS CREDENTIALS:"
    REDIS_PASSWORD=$(az keyvault secret show --vault-name "$key_vault_name" --name "redis-password" --query "value" -o tsv 2>/dev/null || echo "N/A")
    echo "   Redis Password: $REDIS_PASSWORD"
    echo ""
    
    # Django secret key
    print_status "🔐 DJANGO SECRET KEY:"
    DJANGO_SECRET=$(az keyvault secret show --vault-name "$key_vault_name" --name "django-secret-key" --query "value" -o tsv 2>/dev/null || echo "N/A")
    echo "   Django Secret: ${DJANGO_SECRET:0:20}..."
    echo ""
    
    # Service API keys
    print_status "🌐 SERVICE API KEYS:"
    for service in "${SERVICES[@]}"; do
        API_KEY=$(az keyvault secret show --vault-name "$key_vault_name" --name "${service}-service-api-key" --query "value" -o tsv 2>/dev/null || echo "N/A")
        echo "   ${service^} API Key: ${API_KEY:0:20}..."
    done
    echo ""
    
    # Connection strings
    print_status "🔗 CONNECTION STRINGS:"
    echo "   Available in Key Vault:"
    echo "   - redis-connection-string"
    echo "   - storage-connection-string"
    echo "   - app-insights-connection-string"
    echo "   - <service>-db-connection-string (for each service)"
    echo ""
    
    print_success "All credentials retrieved successfully!"
    print_warning "Keep these credentials secure and never commit them to version control."
}

# Function to show service URLs
show_service_urls() {
    local env=${1:-"dev"}
    
    echo ""
    print_status "=== SERVICE ACCESS URLS ==="
    echo ""
    
    # Get AKS cluster info
    if [[ -d "terraform" ]]; then
        cd terraform
        if terraform show >/dev/null 2>&1; then
            RESOURCE_GROUP=$(terraform output -raw resource_group_name 2>/dev/null || echo "bidr-$env-k8s")
            AKS_CLUSTER=$(terraform output -raw aks_cluster_name 2>/dev/null || echo "BIDR-$env-aks-cluster")
        else
            RESOURCE_GROUP="bidr-$env-k8s"
            AKS_CLUSTER="BIDR-$env-aks-cluster"
        fi
        cd ..
    else
        RESOURCE_GROUP="bidr-$env-k8s"
        AKS_CLUSTER="BIDR-$env-aks-cluster"
    fi
    
    print_status "Resource Group: $RESOURCE_GROUP"
    print_status "AKS Cluster: $AKS_CLUSTER"
    echo ""
    
    print_status "To get the external IP of your services:"
    echo "   kubectl get services --all-namespaces"
    echo ""
    
    print_status "To access admin interfaces:"
    echo "   http://<EXTERNAL_IP>/admin/auth/"
    echo "   http://<EXTERNAL_IP>/admin/chat/"
    echo "   http://<EXTERNAL_IP>/admin/payment/"
    echo "   http://<EXTERNAL_IP>/admin/resolution/"
    echo "   http://<EXTERNAL_IP>/admin/products/"
    echo "   http://<EXTERNAL_IP>/admin/notifications/"
    echo "   http://<EXTERNAL_IP>/admin/transactions/"
    echo "   http://<EXTERNAL_IP>/admin/reviews/"
    echo ""
}

# Function to export credentials to environment file
export_credentials() {
    local env=${1:-"dev"}
    local key_vault_name=$(get_keyvault_name "$env")
    local output_file=".env.$env"
    
    print_status "Exporting credentials to $output_file..."
    
    # Create .env file
    cat > "$output_file" << EOF
# BIDR $env Environment Variables
# Generated on $(date)
# DO NOT COMMIT THIS FILE TO VERSION CONTROL

# Database
DATABASE_USER=$(az keyvault secret show --vault-name "$key_vault_name" --name "database-user" --query "value" -o tsv 2>/dev/null || echo "")
DATABASE_PASSWORD=$(az keyvault secret show --vault-name "$key_vault_name" --name "database-password" --query "value" -o tsv 2>/dev/null || echo "")

# Redis
REDIS_PASSWORD=$(az keyvault secret show --vault-name "$key_vault_name" --name "redis-password" --query "value" -o tsv 2>/dev/null || echo "")

# Django
DJANGO_SECRET_KEY=$(az keyvault secret show --vault-name "$key_vault_name" --name "django-secret-key" --query "value" -o tsv 2>/dev/null || echo "")

# Admin
ADMIN_PASSWORD=$(az keyvault secret show --vault-name "$key_vault_name" --name "admin-password" --query "value" -o tsv 2>/dev/null || echo "")

EOF

    # Add service-specific passwords
    SERVICES=("auth" "chat" "payment" "resolution" "product" "notifications" "transactions" "reviews")
    
    echo "" >> "$output_file"
    echo "# Service-specific Admin Passwords" >> "$output_file"
    
    for service in "${SERVICES[@]}"; do
        SERVICE_PASSWORD=$(az keyvault secret show --vault-name "$key_vault_name" --name "${service}-service-admin-password" --query "value" -o tsv 2>/dev/null || echo "")
        echo "${service^^}_ADMIN_PASSWORD=$SERVICE_PASSWORD" >> "$output_file"
    done
    
    echo "" >> "$output_file"
    echo "# Service API Keys" >> "$output_file"
    
    for service in "${SERVICES[@]}"; do
        API_KEY=$(az keyvault secret show --vault-name "$key_vault_name" --name "${service}-service-api-key" --query "value" -o tsv 2>/dev/null || echo "")
        echo "${service^^}_API_KEY=$API_KEY" >> "$output_file"
    done
    
    print_success "Credentials exported to $output_file"
    print_warning "Remember to add $output_file to your .gitignore file!"
}

# Main function
main() {
    local env=${1:-"dev"}
    local action=${2:-"show"}
    
    if [[ "$env" != "dev" && "$env" != "uat" && "$env" != "prod" ]]; then
        print_error "Invalid environment. Use: dev, uat, or prod"
        exit 1
    fi
    
    case "$action" in
        "show")
            show_credentials "$env"
            show_service_urls "$env"
            ;;
        "export")
            export_credentials "$env"
            ;;
        *)
            print_error "Invalid action. Use: show or export"
            exit 1
            ;;
    esac
}

# Help function
show_help() {
    echo "BIDR Admin Credentials Retrieval Script"
    echo ""
    echo "Usage: $0 [ENVIRONMENT] [ACTION]"
    echo ""
    echo "ENVIRONMENT:"
    echo "  dev     Development environment (default)"
    echo "  uat     UAT environment"
    echo "  prod    Production environment"
    echo ""
    echo "ACTION:"
    echo "  show    Display credentials (default)"
    echo "  export  Export credentials to .env file"
    echo ""
    echo "Examples:"
    echo "  $0                    # Show dev credentials"
    echo "  $0 dev show           # Show dev credentials"
    echo "  $0 uat export         # Export UAT credentials to .env.uat"
    echo "  $0 prod show          # Show production credentials"
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
