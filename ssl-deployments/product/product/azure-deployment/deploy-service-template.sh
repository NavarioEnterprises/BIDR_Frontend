#!/bin/bash

# Generic Azure App Service Deployment Template for BIDR Services
# This template is used by individual service deployment scripts

# Function to deploy a BIDR service to Azure App Service
deploy_bidr_service() {
    local SERVICE_NAME="$1"
    local SERVICE_DIR="$2"
    local SERVICE_PORT="$3"
    local DATABASE_NAME="$4"
    local ADDITIONAL_ENV_VARS="$5"

    # Load configuration
    if [ -f "deployment-config.env" ]; then
        source deployment-config.env
    else
        echo -e "${RED}Error: deployment-config.env not found. Run 00-setup-infrastructure.sh first${NC}"
        exit 1
    fi

    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'

    WEB_APP_NAME="bidr-${SERVICE_NAME}-service"
    IMAGE_NAME="bidr-${SERVICE_NAME}-service"

    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   Deploying ${SERVICE_NAME^} Service   ${NC}"
    echo -e "${GREEN}========================================${NC}"

    # Step 1: Build and push Docker image
    echo -e "${YELLOW}Step 1: Building and pushing Docker image...${NC}"
    
    # Navigate to service directory
    if [ -d "$SERVICE_DIR" ]; then
        cd "$SERVICE_DIR"
    else
        echo -e "${RED}Error: Service directory '$SERVICE_DIR' not found${NC}"
        exit 1
    fi

    # Build and push image
    az acr build \
        --registry $CONTAINER_REGISTRY \
        --image $IMAGE_NAME:latest \
        .

    # Return to root directory
    cd ..

    echo -e "${GREEN}Image built and pushed: $ACR_LOGIN_SERVER/$IMAGE_NAME:latest${NC}"

    # Step 2: Create Web App
    echo -e "${YELLOW}Step 2: Creating/updating Web App...${NC}"
    
    # Check if web app exists
    if az webapp show --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
        echo -e "${BLUE}Web App '$WEB_APP_NAME' already exists, updating...${NC}"
        
        # Update container image
        az webapp config container set \
            --name $WEB_APP_NAME \
            --resource-group $RESOURCE_GROUP \
            --container-image-name $ACR_LOGIN_SERVER/$IMAGE_NAME:latest \
            --container-registry-url https://$ACR_LOGIN_SERVER \
            --container-registry-user $ACR_USERNAME \
            --container-registry-password $ACR_PASSWORD
    else
        echo -e "${GREEN}Creating new Web App: $WEB_APP_NAME${NC}"
        
        # Create web app
        az webapp create \
            --resource-group $RESOURCE_GROUP \
            --plan $APP_SERVICE_PLAN \
            --name $WEB_APP_NAME \
            --deployment-container-image-name $ACR_LOGIN_SERVER/$IMAGE_NAME:latest

        # Configure container registry
        az webapp config container set \
            --name $WEB_APP_NAME \
            --resource-group $RESOURCE_GROUP \
            --container-image-name $ACR_LOGIN_SERVER/$IMAGE_NAME:latest \
            --container-registry-url https://$ACR_LOGIN_SERVER \
            --container-registry-user $ACR_USERNAME \
            --container-registry-password $ACR_PASSWORD
    fi

    # Step 3: Configure application settings
    echo -e "${YELLOW}Step 3: Configuring application settings...${NC}"
    
    # Generate new secret key for this service
    SERVICE_SECRET_KEY=$(openssl rand -base64 32)
    
    # Base environment variables
    ENV_SETTINGS=(
        "SECRET_KEY=$SERVICE_SECRET_KEY"
        "DEBUG=False"
        "ALLOWED_HOSTS=$WEB_APP_NAME.azurewebsites.net"
        "WEBSITES_ENABLE_APP_SERVICE_STORAGE=false"
        "WEBSITES_PORT=$SERVICE_PORT"
        "DB_HOST=$DB_HOST"
        "DB_NAME=bidr_$DATABASE_NAME"
        "DB_USER=$DB_ADMIN_USER@$DB_SERVER_NAME"
        "DB_PASSWORD=$DB_ADMIN_PASSWORD"
        "DB_PORT=5432"
    )

    # Add additional environment variables if provided
    if [ ! -z "$ADDITIONAL_ENV_VARS" ]; then
        IFS=',' read -ra ADDR <<< "$ADDITIONAL_ENV_VARS"
        for env_var in "${ADDR[@]}"; do
            ENV_SETTINGS+=("$env_var")
        done
    fi

    # Apply settings
    az webapp config appsettings set \
        --resource-group $RESOURCE_GROUP \
        --name $WEB_APP_NAME \
        --settings "${ENV_SETTINGS[@]}"

    # Step 4: Configure logging and monitoring
    echo -e "${YELLOW}Step 4: Configuring logging and monitoring...${NC}"
    
    # Enable application logging
    az webapp log config \
        --resource-group $RESOURCE_GROUP \
        --name $WEB_APP_NAME \
        --application-logging filesystem \
        --level information

    # Set up health check
    az webapp config set \
        --resource-group $RESOURCE_GROUP \
        --name $WEB_APP_NAME \
        --health-check-path "/health/"

    # Step 5: Restart and get URL
    echo -e "${YELLOW}Step 5: Finalizing deployment...${NC}"
    
    # Restart web app
    az webapp restart \
        --resource-group $RESOURCE_GROUP \
        --name $WEB_APP_NAME

    # Get service URL
    SERVICE_URL="https://$WEB_APP_NAME.azurewebsites.net"

    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   ${SERVICE_NAME^} Service Deployed!   ${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Service URL: $SERVICE_URL${NC}"
    echo -e "${GREEN}Admin URL: $SERVICE_URL/admin/${NC}"
    echo -e "${GREEN}API URL: $SERVICE_URL/api/${NC}"
    echo -e "${GREEN}Health Check: $SERVICE_URL/health/${NC}"
    echo -e "${GREEN}========================================${NC}"

    # Update deployment config with service URL
    update_service_url "$SERVICE_NAME" "$SERVICE_URL"

    echo -e "${YELLOW}To run database migrations:${NC}"
    echo -e "${GREEN}az webapp ssh --resource-group $RESOURCE_GROUP --name $WEB_APP_NAME${NC}"
    echo -e "${GREEN}Then run: python manage.py migrate${NC}"
    echo ""
}

# Function to update service URL in config file
update_service_url() {
    local service_name="$1"
    local service_url="$2"
    local config_file="deployment-config.env"
    
    # Convert service name to uppercase for env var
    local env_var_name="${service_name^^}_SERVICE_URL"
    
    # Update the config file
    if grep -q "^${env_var_name}=" "$config_file"; then
        # Update existing entry
        sed -i.bak "s|^${env_var_name}=.*|${env_var_name}=${service_url}|" "$config_file"
    else
        # Add new entry
        echo "${env_var_name}=${service_url}" >> "$config_file"
    fi
}
