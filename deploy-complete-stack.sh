#!/bin/bash

# BIDR Complete Stack Deployment Script
# This script deploys the entire BIDR backend infrastructure and applications

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="${ENVIRONMENT:-production}"
DEPLOY_INFRASTRUCTURE="${DEPLOY_INFRASTRUCTURE:-true}"
SKIP_TESTS="${SKIP_TESTS:-false}"
FORCE_REBUILD="${FORCE_REBUILD:-false}"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Help function
show_help() {
    echo "BIDR Complete Stack Deployment"
    echo "=============================="
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -e, --environment ENV     Environment (production|uat) [default: production]"
    echo "  -i, --infrastructure      Deploy infrastructure with Terraform"
    echo "  -s, --skip-tests          Skip health checks and tests"
    echo "  -f, --force-rebuild       Force rebuild all Docker images"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  ENVIRONMENT              Environment to deploy to"
    echo "  DEPLOY_INFRASTRUCTURE    Whether to deploy infrastructure (true|false)"
    echo "  SKIP_TESTS              Skip tests (true|false)"
    echo "  FORCE_REBUILD           Force rebuild images (true|false)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Deploy to production"
    echo "  $0 -e uat                            # Deploy to UAT"
    echo "  $0 -e uat -i                        # Deploy UAT with infrastructure"
    echo "  $0 -f                                # Force rebuild all images"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -i|--infrastructure)
            DEPLOY_INFRASTRUCTURE="true"
            shift
            ;;
        -s|--skip-tests)
            SKIP_TESTS="true"
            shift
            ;;
        -f|--force-rebuild)
            FORCE_REBUILD="true"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(production|uat)$ ]]; then
    echo -e "${RED}❌ Invalid environment: $ENVIRONMENT. Must be 'production' or 'uat'${NC}"
    exit 1
fi

# Banner
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    BIDR STACK DEPLOYMENT                     ║"
echo "║                                                              ║"
echo "║  🚀 Complete Infrastructure & Application Deployment        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}📋 Configuration:${NC}"
echo -e "   Environment: ${GREEN}$ENVIRONMENT${NC}"
echo -e "   Deploy Infrastructure: ${GREEN}$DEPLOY_INFRASTRUCTURE${NC}"
echo -e "   Skip Tests: ${GREEN}$SKIP_TESTS${NC}"
echo -e "   Force Rebuild: ${GREEN}$FORCE_REBUILD${NC}"
echo ""

# Pre-flight checks
echo -e "${BLUE}🔍 Pre-flight checks...${NC}"

# Check required tools
required_tools=("az" "kubectl" "docker" "terraform")
for tool in "${required_tools[@]}"; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}❌ Required tool '$tool' is not installed${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✅ All required tools are available${NC}"

# Check Azure login
if ! az account show &>/dev/null; then
    echo -e "${YELLOW}⚠️  Not logged into Azure. Please run 'az login'${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Azure authentication verified${NC}"

# Infrastructure Deployment
if [[ "$DEPLOY_INFRASTRUCTURE" == "true" ]]; then
    echo ""
    echo -e "${BLUE}🏗️  Deploying Infrastructure with Terraform...${NC}"
    
    cd "$SCRIPT_DIR/terraform"
    
    echo -e "${CYAN}📦 Initializing Terraform...${NC}"
    terraform init
    
    echo -e "${CYAN}📋 Planning infrastructure changes...${NC}"
    terraform plan -var-file="${ENVIRONMENT}.tfvars" -out="${ENVIRONMENT}.tfplan"
    
    echo -e "${CYAN}🚀 Applying infrastructure changes...${NC}"
    terraform apply -auto-approve "${ENVIRONMENT}.tfplan"
    
    echo -e "${GREEN}✅ Infrastructure deployment completed${NC}"
    
    # Get outputs
    echo -e "${CYAN}📤 Getting infrastructure outputs...${NC}"
    LOAD_BALANCER_IP=$(terraform output -raw load_balancer_public_ip 2>/dev/null || echo "")
    ACR_NAME=$(terraform output -raw acr_name)
    AKS_CLUSTER=$(terraform output -raw aks_cluster_name)
    RESOURCE_GROUP=$(terraform output -raw resource_group_name)
    
    cd "$SCRIPT_DIR"
else
    echo -e "${YELLOW}⚠️  Skipping infrastructure deployment${NC}"
    # Use default values or environment variables
    ACR_NAME="${ACR_NAME:-BIDRcontainerregistry}"
    if [[ "$ENVIRONMENT" == "uat" ]]; then
        AKS_CLUSTER="${AKS_CLUSTER:-BIDR-uat-aks-cluster}"
        RESOURCE_GROUP="${RESOURCE_GROUP:-bidr-uat-k8s}"
    else
        AKS_CLUSTER="${AKS_CLUSTER:-BIDR-aks-cluster}"
        RESOURCE_GROUP="${RESOURCE_GROUP:-bidr-k8s}"
    fi
fi

# Application Deployment
echo ""
echo -e "${BLUE}🚀 Deploying Applications...${NC}"

# Set environment variables for build script
export ENVIRONMENT
export FORCE_REBUILD
export ACR_NAME
export AKS_CLUSTER  
export RESOURCE_GROUP

# Run the build and deploy script
if [[ "$DEPLOY_INFRASTRUCTURE" == "true" ]]; then
    ./build-and-deploy.sh --full-deploy
else
    ./build-and-deploy.sh
fi

# Post-deployment verification
if [[ "$SKIP_TESTS" != "true" ]]; then
    echo ""
    echo -e "${BLUE}🏥 Running post-deployment verification...${NC}"
    
    # Wait for load balancer IP
    echo -e "${CYAN}⏳ Waiting for load balancer IP...${NC}"
    
    for i in {1..20}; do
        LOAD_BALANCER_IP=$(kubectl get service bidr-load-balancer -n bidr -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        
        if [ -n "$LOAD_BALANCER_IP" ] && [ "$LOAD_BALANCER_IP" != "null" ] && [ "$LOAD_BALANCER_IP" != "<pending>" ]; then
            echo -e "${GREEN}✅ Load Balancer IP obtained: $LOAD_BALANCER_IP${NC}"
            break
        fi
        
        echo -e "${YELLOW}   Waiting for IP assignment... (attempt $i/20)${NC}"
        sleep 30
    done
    
    if [ -n "$LOAD_BALANCER_IP" ] && [ "$LOAD_BALANCER_IP" != "null" ] && [ "$LOAD_BALANCER_IP" != "<pending>" ]; then
        echo ""
        echo -e "${CYAN}🏥 Running health checks...${NC}"
        
        # Test main health endpoint
        if curl -f -s "http://$LOAD_BALANCER_IP/health" > /dev/null; then
            echo -e "${GREEN}✅ Main health check passed${NC}"
        else
            echo -e "${RED}❌ Main health check failed${NC}"
        fi
        
        # Test environment endpoint if UAT
        if [[ "$ENVIRONMENT" == "uat" ]]; then
            if curl -f -s "http://$LOAD_BALANCER_IP/env" > /dev/null; then
                echo -e "${GREEN}✅ Environment endpoint accessible${NC}"
            else
                echo -e "${YELLOW}⚠️  Environment endpoint not accessible${NC}"
            fi
        fi
        
        # Test service endpoints
        services=("auth" "chat" "payment" "product" "notifications" "resolution" "transactions" "reviews")
        
        for service in "${services[@]}"; do
            if curl -f -s -o /dev/null "http://$LOAD_BALANCER_IP/$service/" --max-time 10; then
                echo -e "${GREEN}✅ $service service accessible${NC}"
            else
                echo -e "${YELLOW}⚠️  $service service not accessible (may still be starting)${NC}"
            fi
        done
    else
        echo -e "${YELLOW}⚠️  Load Balancer IP not assigned yet. Manual verification required.${NC}"
    fi
fi

# Final status report
echo ""
echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                    DEPLOYMENT COMPLETE                      ║${NC}" 
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"

echo ""
echo -e "${GREEN}🎉 BIDR Backend deployment completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Deployment Summary:${NC}"
echo -e "   Environment: ${GREEN}$ENVIRONMENT${NC}"
echo -e "   Resource Group: ${GREEN}$RESOURCE_GROUP${NC}"
echo -e "   AKS Cluster: ${GREEN}$AKS_CLUSTER${NC}"
echo -e "   Container Registry: ${GREEN}$ACR_NAME${NC}"

if [ -n "$LOAD_BALANCER_IP" ] && [ "$LOAD_BALANCER_IP" != "null" ] && [ "$LOAD_BALANCER_IP" != "<pending>" ]; then
    echo ""
    echo -e "${BLUE}🌐 Application Access:${NC}"
    echo -e "   Main Application: ${CYAN}http://$LOAD_BALANCER_IP${NC}"
    echo -e "   Admin Panel:      ${CYAN}http://$LOAD_BALANCER_IP/admin${NC}"
    
    if [[ "$ENVIRONMENT" == "uat" ]]; then
        echo -e "   Environment Info: ${CYAN}http://$LOAD_BALANCER_IP/env${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}📋 Service Endpoints:${NC}"
    echo -e "   Auth Service:         ${CYAN}http://$LOAD_BALANCER_IP/auth${NC}"
    echo -e "   Chat Service:         ${CYAN}http://$LOAD_BALANCER_IP/chat${NC}"
    echo -e "   Payment Service:      ${CYAN}http://$LOAD_BALANCER_IP/payment${NC}"
    echo -e "   Product Service:      ${CYAN}http://$LOAD_BALANCER_IP/product${NC}"
    echo -e "   Notification Service: ${CYAN}http://$LOAD_BALANCER_IP/notifications${NC}"
    echo -e "   Resolution Service:   ${CYAN}http://$LOAD_BALANCER_IP/resolution${NC}"
    echo -e "   Transaction Service:  ${CYAN}http://$LOAD_BALANCER_IP/transactions${NC}"
    echo -e "   Reviews Service:      ${CYAN}http://$LOAD_BALANCER_IP/reviews${NC}"
else
    echo ""
    echo -e "${YELLOW}⚠️  Load Balancer IP not yet assigned. Please wait a few minutes and check:${NC}"
    echo -e "   ${CYAN}kubectl get service bidr-load-balancer -n bidr${NC}"
fi

echo ""
echo -e "${BLUE}🔧 Useful Commands:${NC}"
echo -e "   Check status:      ${CYAN}kubectl get pods,services,ingress -n bidr${NC}"
echo -e "   View logs:         ${CYAN}kubectl logs -f deployment/<service-name> -n bidr${NC}"
echo -e "   Shell access:      ${CYAN}kubectl exec -it deployment/<service-name> -n bidr -- /bin/bash${NC}"
echo -e "   Port forward:      ${CYAN}kubectl port-forward service/<service-name> 8080:80 -n bidr${NC}"

echo ""
echo -e "${GREEN}🎊 BIDR Backend is ready for use!${NC}"

# Save deployment info to file
cat > "deployment-info-${ENVIRONMENT}.txt" << EOF
BIDR Backend Deployment Information
===================================

Environment: $ENVIRONMENT
Deployment Date: $(date)
Resource Group: $RESOURCE_GROUP
AKS Cluster: $AKS_CLUSTER
Container Registry: $ACR_NAME

Load Balancer IP: $LOAD_BALANCER_IP

Application URLs:
- Main Application: http://$LOAD_BALANCER_IP
- Admin Panel: http://$LOAD_BALANCER_IP/admin

Service Endpoints:
- Auth Service: http://$LOAD_BALANCER_IP/auth
- Chat Service: http://$LOAD_BALANCER_IP/chat
- Payment Service: http://$LOAD_BALANCER_IP/payment
- Product Service: http://$LOAD_BALANCER_IP/product
- Notification Service: http://$LOAD_BALANCER_IP/notifications
- Resolution Service: http://$LOAD_BALANCER_IP/resolution
- Transaction Service: http://$LOAD_BALANCER_IP/transactions
- Reviews Service: http://$LOAD_BALANCER_IP/reviews

Useful Commands:
- kubectl get pods,services,ingress -n bidr
- kubectl logs -f deployment/<service-name> -n bidr
- kubectl exec -it deployment/<service-name> -n bidr -- /bin/bash

EOF

echo -e "${GREEN}📝 Deployment information saved to: deployment-info-${ENVIRONMENT}.txt${NC}"