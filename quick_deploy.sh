#!/bin/bash

# Quick deployment script for BIDR services
# Usage: ./quick_deploy.sh [service_name|all]

NAMESPACE="bidr"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Service configurations
declare -A SERVICES
SERVICES[auth]="auth-service"
SERVICES[products]="product-management-service" 
SERVICES[reviews]="reviews-service"
SERVICES[chat]="chat-service"
SERVICES[payments]="payment-service"
SERVICES[notifications]="notifications-service"
SERVICES[transactions]="transactions-service"
SERVICES[resolution]="resolution-service"
SERVICES[nginx]="nginx-proxy"

# Deployment files
declare -A DEPLOYMENT_FILES
DEPLOYMENT_FILES[auth]="k8s/overlays/uat/auth-service.yaml"
DEPLOYMENT_FILES[products]="k8s/overlays/uat/product-django-real.yaml"
DEPLOYMENT_FILES[reviews]="k8s/overlays/uat/reviews-service-real.yaml"
DEPLOYMENT_FILES[chat]="k8s/overlays/uat/chat-service.yaml"
DEPLOYMENT_FILES[payments]="k8s/overlays/uat/payment-service.yaml"
DEPLOYMENT_FILES[notifications]="k8s/overlays/uat/notifications-service.yaml"
DEPLOYMENT_FILES[transactions]="k8s/overlays/uat/transactions-service.yaml"
DEPLOYMENT_FILES[resolution]="k8s/overlays/uat/resolution-service.yaml"

print_header() {
    echo "======================================="
    echo "🚀 BIDR Quick Deploy Script"
    echo "======================================="
    echo "📅 $(date)"
    echo "📁 Working Directory: $SCRIPT_DIR"
    echo "======================================="
    echo ""
}

list_services() {
    echo "📋 Available Services:"
    echo "----------------------"
    echo " all     - Deploy all services"
    echo " nginx   - Deploy nginx configuration"
    for service in "${!SERVICES[@]}"; do
        echo " $service - Deploy ${SERVICES[$service]}"
    done
    echo ""
}

deploy_nginx() {
    echo "🌐 Deploying nginx configuration..."
    
    cd "$SCRIPT_DIR/nginx"
    
    # Backup first
    ./backup-nginx-config.sh
    
    # Apply configuration
    echo "y" | ./apply-django-url-prefixes.sh
    
    echo "✅ Nginx deployment completed"
}

deploy_service() {
    local service_key="$1"
    local service_name="${SERVICES[$service_key]}"
    local deployment_file="${DEPLOYMENT_FILES[$service_key]}"
    
    echo "🚀 Deploying $service_name..."
    
    # Apply deployment file
    if [ -f "$SCRIPT_DIR/$deployment_file" ]; then
        kubectl apply -f "$SCRIPT_DIR/$deployment_file"
        
        # Restart deployment
        kubectl rollout restart deployment "$service_name" -n "$NAMESPACE"
        
        # Wait for rollout
        kubectl rollout status deployment "$service_name" -n "$NAMESPACE" --timeout=300s
        
        echo "✅ $service_name deployed successfully"
    else
        echo "❌ Deployment file not found: $deployment_file"
        return 1
    fi
}

deploy_all() {
    echo "🌟 Deploying all services..."
    echo ""
    
    local success=0
    local total=0
    
    # Deploy nginx first
    echo "📦 1/$(( ${#SERVICES[@]} + 1 )) - nginx"
    if deploy_nginx; then
        ((success++))
    fi
    ((total++))
    
    # Deploy all services
    local counter=2
    for service in "${!SERVICES[@]}"; do
        echo ""
        echo "📦 $counter/$(( ${#SERVICES[@]} + 1 )) - $service"
        if deploy_service "$service"; then
            ((success++))
        fi
        ((total++))
        ((counter++))
    done
    
    echo ""
    echo "======================================="
    echo "📊 Deployment Summary: $success/$total successful"
    echo "======================================="
}

show_status() {
    echo ""
    echo "📊 Current Deployment Status:"
    echo "-----------------------------"
    
    for service in "${!SERVICES[@]}"; do
        service_name="${SERVICES[$service]}"
        status=$(kubectl get deployment "$service_name" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}/{.spec.replicas}' 2>/dev/null || echo "Not Found")
        printf "%-15s - %s\n" "$service_name" "$status"
    done
    echo ""
}

main() {
    print_header
    
    if [ $# -eq 0 ]; then
        list_services
        echo "Usage: $0 <service_name|all>"
        echo ""
        echo "Examples:"
        echo "  $0 products    # Deploy products service"
        echo "  $0 all         # Deploy all services"
        echo "  $0 nginx       # Deploy nginx only"
        exit 1
    fi
    
    local command="$1"
    
    case "$command" in
        "all")
            deploy_all
            ;;
        "nginx")
            deploy_nginx
            ;;
        *)
            if [[ -n "${SERVICES[$command]}" ]]; then
                deploy_service "$command"
            else
                echo "❌ Unknown service: $command"
                list_services
                exit 1
            fi
            ;;
    esac
    
    show_status
}

# Run main function
main "$@"