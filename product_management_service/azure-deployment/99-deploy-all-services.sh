#!/bin/bash

# Master Deployment Script for All BIDR Services
# This script orchestrates the deployment of all BIDR microservices to Azure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Deployment options
SKIP_INFRASTRUCTURE=false
DEPLOY_INDIVIDUAL_SERVICES=true
SKIP_DATABASE_MIGRATION=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-infrastructure)
            SKIP_INFRASTRUCTURE=true
            shift
            ;;
        --skip-db-migration)
            SKIP_DATABASE_MIGRATION=true
            shift
            ;;
        --services-only)
            SKIP_INFRASTRUCTURE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --skip-infrastructure    Skip infrastructure setup (assumes already done)"
            echo "  --skip-db-migration      Skip database migrations"
            echo "  --services-only          Only deploy services (skip infrastructure)"
            echo "  --help                   Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}     BIDR Complete Deployment         ${NC}"
echo -e "${CYAN}========================================${NC}"

START_TIME=$(date +%s)

# Step 1: Infrastructure Setup
if [ "$SKIP_INFRASTRUCTURE" = false ]; then
    echo -e "${GREEN}Step 1: Setting up Azure infrastructure...${NC}"
    chmod +x 00-setup-infrastructure.sh
    bash 00-setup-infrastructure.sh
    
    echo -e "${YELLOW}Waiting 30 seconds for infrastructure to stabilize...${NC}"
    sleep 30
else
    echo -e "${BLUE}Skipping infrastructure setup as requested${NC}"
fi

# Step 2: Deploy Core Services (Authentication first)
echo -e "${GREEN}Step 2: Deploying core services...${NC}"

# Authentication Service (must be first - other services depend on it)
echo -e "${YELLOW}Deploying Authentication Service...${NC}"
chmod +x 01-deploy-authentication-service.sh
bash 01-deploy-authentication-service.sh

echo -e "${YELLOW}Waiting 60 seconds for authentication service to stabilize...${NC}"
sleep 60

# Step 3: Deploy Business Logic Services
echo -e "${GREEN}Step 3: Deploying business logic services...${NC}"

services=(
    "02-deploy-product-service.sh:Product Management Service"
    "04-deploy-payment-service.sh:Payment Service" 
    "07-deploy-transactions-service.sh:Transactions Service"
)

for service_info in "${services[@]}"; do
    IFS=":" read -r script_name service_name <<< "$service_info"
    echo -e "${YELLOW}Deploying ${service_name}...${NC}"
    chmod +x "$script_name"
    bash "$script_name"
    echo -e "${YELLOW}Waiting 30 seconds before next service...${NC}"
    sleep 30
done

# Step 4: Deploy Support Services
echo -e "${GREEN}Step 4: Deploying support services...${NC}"

support_services=(
    "03-deploy-notifications-service.sh:Notifications Service"
    "05-deploy-resolution-service.sh:Resolution Service"
    "06-deploy-reviews-service.sh:Reviews Service"
    "08-deploy-chat-service.sh:Chat Service"
)

for service_info in "${support_services[@]}"; do
    IFS=":" read -r script_name service_name <<< "$service_info"
    echo -e "${YELLOW}Deploying ${service_name}...${NC}"
    chmod +x "azure-deployment/$script_name"
    bash "azure-deployment/$script_name"
    echo -e "${YELLOW}Waiting 30 seconds before next service...${NC}"
    sleep 30
done

# Step 5: Database Migrations and Setup
if [ "$SKIP_DATABASE_MIGRATION" = false ]; then
    echo -e "${GREEN}Step 5: Running database migrations...${NC}"
    
    # Load configuration
    if [ -f "deployment-config.env" ]; then
        source deployment-config.env
    else
        echo -e "${RED}Error: deployment-config.env not found${NC}"
        exit 1
    fi
    
    services_db=(
        "bidr-authentication-service"
        "bidr-product-service"
        "bidr-payment-service"
        "bidr-transactions-service"
        "bidr-notifications-service"
        "bidr-resolution-service"
        "bidr-reviews-service"
        "bidr-chat-service"
    )
    
    for service in "${services_db[@]}"; do
        echo -e "${YELLOW}Running migrations for $service...${NC}"
        
        # Run migrations
        az webapp ssh --resource-group $RESOURCE_GROUP --name $service --command "cd /home/site/wwwroot && python manage.py migrate" || {
            echo -e "${RED}Migration failed for $service, but continuing...${NC}"
        }
        
        # Create superuser for admin access
        echo -e "${YELLOW}Creating admin user for $service...${NC}"
        az webapp ssh --resource-group $RESOURCE_GROUP --name $service --command "cd /home/site/wwwroot && echo \"from django.contrib.auth.models import User; User.objects.filter(username='bidr_admin').exists() or User.objects.create_superuser('bidr_admin', 'admin@bidr.com', 'admin123')\" | python manage.py shell" || {
            echo -e "${RED}Admin user creation failed for $service, but continuing...${NC}"
        }
    done
else
    echo -e "${BLUE}Skipping database migrations as requested${NC}"
fi

# Step 6: Generate Deployment Summary
echo -e "${GREEN}Step 6: Generating deployment summary...${NC}"

END_TIME=$(date +%s)
DEPLOYMENT_TIME=$((END_TIME - START_TIME))

# Load final configuration to get service URLs
if [ -f "deployment-config.env" ]; then
    source deployment-config.env
fi

# Create deployment summary
cat > deployment-summary.txt << EOF
BIDR Microservices Deployment Summary
=====================================
Deployment Date: $(date)
Deployment Time: $((DEPLOYMENT_TIME / 60)) minutes $((DEPLOYMENT_TIME % 60)) seconds

Infrastructure:
- Resource Group: $RESOURCE_GROUP
- Container Registry: $ACR_LOGIN_SERVER
- App Service Plan: $APP_SERVICE_PLAN
- Database Server: $DB_SERVER_NAME.postgres.database.azure.com
- Location: $LOCATION

Service URLs:
- Authentication Service: $AUTHENTICATION_SERVICE_URL
- Product Management Service: $PRODUCT_SERVICE_URL
- Payment Service: $PAYMENT_SERVICE_URL
- Transactions Service: $TRANSACTIONS_SERVICE_URL
- Notifications Service: $NOTIFICATIONS_SERVICE_URL
- Resolution Service: $RESOLUTION_SERVICE_URL
- Reviews Service: $REVIEWS_SERVICE_URL
- Chat Service: $CHAT_SERVICE_URL

Admin Access:
- Username: bidr_admin
- Password: admin123

Each service admin panel: [SERVICE_URL]/admin/
Each service API: [SERVICE_URL]/api/
Each service health check: [SERVICE_URL]/health/

Next Steps:
1. Test each service health endpoint
2. Configure inter-service communication
3. Set up custom domains (optional)
4. Configure SSL certificates
5. Set up monitoring and alerting
6. Configure backup strategies

Troubleshooting:
- View logs: az webapp log tail --resource-group $RESOURCE_GROUP --name [SERVICE_NAME]
- SSH to service: az webapp ssh --resource-group $RESOURCE_GROUP --name [SERVICE_NAME]
- Restart service: az webapp restart --resource-group $RESOURCE_GROUP --name [SERVICE_NAME]
EOF

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}     Deployment Complete!              ${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}Total Deployment Time: $((DEPLOYMENT_TIME / 60)) minutes $((DEPLOYMENT_TIME % 60)) seconds${NC}"
echo -e "${GREEN}Resource Group: $RESOURCE_GROUP${NC}"
echo -e "${GREEN}All services are now running on Azure!${NC}"
echo -e "${CYAN}========================================${NC}"

# Display service URLs
echo -e "${YELLOW}Service URLs:${NC}"
if [ ! -z "$AUTHENTICATION_SERVICE_URL" ]; then
    echo -e "${GREEN}Authentication: $AUTHENTICATION_SERVICE_URL${NC}"
fi
if [ ! -z "$PRODUCT_SERVICE_URL" ]; then
    echo -e "${GREEN}Product Management: $PRODUCT_SERVICE_URL${NC}"
fi
if [ ! -z "$PAYMENT_SERVICE_URL" ]; then
    echo -e "${GREEN}Payment: $PAYMENT_SERVICE_URL${NC}"
fi
if [ ! -z "$TRANSACTIONS_SERVICE_URL" ]; then
    echo -e "${GREEN}Transactions: $TRANSACTIONS_SERVICE_URL${NC}"
fi
if [ ! -z "$NOTIFICATIONS_SERVICE_URL" ]; then
    echo -e "${GREEN}Notifications: $NOTIFICATIONS_SERVICE_URL${NC}"
fi
if [ ! -z "$RESOLUTION_SERVICE_URL" ]; then
    echo -e "${GREEN}Resolution: $RESOLUTION_SERVICE_URL${NC}"
fi
if [ ! -z "$REVIEWS_SERVICE_URL" ]; then
    echo -e "${GREEN}Reviews: $REVIEWS_SERVICE_URL${NC}"
fi
if [ ! -z "$CHAT_SERVICE_URL" ]; then
    echo -e "${GREEN}Chat: $CHAT_SERVICE_URL${NC}"
fi

echo -e "${CYAN}========================================${NC}"
echo -e "${YELLOW}Admin credentials: bidr_admin / admin123${NC}"
echo -e "${YELLOW}Deployment summary saved to: deployment-summary.txt${NC}"
echo -e "${CYAN}========================================${NC}"
