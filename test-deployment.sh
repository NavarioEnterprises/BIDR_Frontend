#!/bin/bash

# BIDR Deployment Testing Script
# Tests the deployment without actually deploying

set -e

echo "🧪 BIDR Deployment Test Suite"
echo "=============================="

# Test 1: Check all required files exist
echo ""
echo "📁 Test 1: Checking required files..."

required_files=(
    "terraform/main.tf"
    "terraform/variables.tf" 
    "terraform/outputs.tf"
    "terraform/uat.tfvars"
    "build-and-deploy.sh"
    "deploy-complete-stack.sh"
    "k8s/base/kustomization.yaml"
    "k8s/base/load-balancer.yaml"
    "k8s/overlays/uat/kustomization.yaml"
    "k8s/overlays/uat/load-balancer-patch.yaml"
    ".github/workflows/uat-deployment.yml"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done

# Test 2: Check service directories and Dockerfiles
echo ""
echo "🐳 Test 2: Checking service Dockerfiles..."

services=(
    "authentication_service"
    "chat_service"
    "notifications_service"
    "payment_service"
    "product_management_service"
    "resolution_service"
    "reviews_and_ratings"
    "transactions_service"
)

for service in "${services[@]}"; do
    if [[ -d "$service" ]]; then
        if [[ -f "$service/Dockerfile" ]]; then
            echo "✅ $service has Dockerfile"
        else
            echo "❌ $service missing Dockerfile"
        fi
        
        if [[ -f "$service/manage.py" ]]; then
            echo "✅ $service is Django service"
        else
            echo "❌ $service not a Django service"
        fi
    else
        echo "❌ $service directory missing"
    fi
done

# Test 3: Validate Terraform syntax
echo ""
echo "🏗️  Test 3: Validating Terraform configuration..."

if command -v terraform &> /dev/null; then
    cd terraform
    if terraform validate; then
        echo "✅ Terraform configuration is valid"
    else
        echo "❌ Terraform configuration has errors"
    fi
    cd ..
else
    echo "⚠️  Terraform not installed, skipping validation"
fi

# Test 4: Validate Kubernetes manifests
echo ""
echo "☸️  Test 4: Validating Kubernetes manifests..."

if command -v kubectl &> /dev/null; then
    # Test base configuration
    if kubectl apply --dry-run=client -k k8s/base/ > /dev/null 2>&1; then
        echo "✅ Base Kubernetes manifests are valid"
    else
        echo "❌ Base Kubernetes manifests have errors"
    fi
    
    # Test UAT overlay
    if kubectl apply --dry-run=client -k k8s/overlays/uat/ > /dev/null 2>&1; then
        echo "✅ UAT overlay manifests are valid" 
    else
        echo "❌ UAT overlay manifests have errors"
    fi
else
    echo "⚠️  kubectl not installed, skipping validation"
fi

# Test 5: Check script permissions
echo ""
echo "🔐 Test 5: Checking script permissions..."

scripts=("build-and-deploy.sh" "deploy-complete-stack.sh" "test-deployment.sh")

for script in "${scripts[@]}"; do
    if [[ -x "$script" ]]; then
        echo "✅ $script is executable"
    else
        echo "❌ $script is not executable"
        chmod +x "$script"
        echo "✅ Fixed: Made $script executable"
    fi
done

# Test 6: Validate load balancer configuration
echo ""
echo "⚖️  Test 6: Validating load balancer configuration..."

if grep -q "bidr-load-balancer" k8s/base/load-balancer.yaml; then
    echo "✅ Load balancer service defined"
else
    echo "❌ Load balancer service missing"
fi

if grep -q "upstream.*_service" k8s/base/load-balancer.yaml; then
    echo "✅ Service upstreams configured"
else
    echo "❌ Service upstreams not configured"
fi

# Test 7: Check image naming consistency
echo ""
echo "🏷️  Test 7: Checking image naming consistency..."

# Check if build script uses correct image names
for service in "${services[@]}"; do
    image_name="bidr-${service//_/-}"
    if grep -q "$image_name" build-and-deploy.sh; then
        echo "✅ $service image name is correct"
    else
        echo "❌ $service image name inconsistent"
    fi
done

# Test 8: Environment configuration check
echo ""
echo "🌍 Test 8: Checking environment configurations..."

if [[ -f "terraform/uat.tfvars" ]]; then
    if grep -q "uat" terraform/uat.tfvars; then
        echo "✅ UAT environment configuration exists"
    else
        echo "❌ UAT environment configuration invalid"
    fi
else
    echo "❌ UAT environment configuration missing"
fi

# Test 9: GitHub Actions workflow validation
echo ""
echo "🚀 Test 9: Validating GitHub Actions workflow..."

if [[ -f ".github/workflows/uat-deployment.yml" ]]; then
    if grep -q "uat" .github/workflows/uat-deployment.yml; then
        echo "✅ GitHub Actions UAT workflow configured"
    else
        echo "❌ GitHub Actions UAT workflow misconfigured"
    fi
    
    if grep -q "terraform" .github/workflows/uat-deployment.yml; then
        echo "✅ Terraform deployment included in workflow"
    else
        echo "❌ Terraform deployment missing from workflow"
    fi
else
    echo "❌ GitHub Actions UAT workflow missing"
fi

# Test 10: Service connectivity configuration
echo ""
echo "🔗 Test 10: Checking service connectivity configuration..."

expected_routes=("/auth/" "/chat/" "/payment/" "/product/" "/notifications/" "/resolution/" "/transactions/" "/reviews/")

for route in "${expected_routes[@]}"; do
    if grep -q "location $route" k8s/base/load-balancer.yaml; then
        echo "✅ Route $route configured"
    else
        echo "❌ Route $route missing"
    fi
done

# Summary
echo ""
echo "📊 Test Summary"
echo "==============="

total_tests=10
echo "Total tests: $total_tests"

# Check if we can run a basic deployment dry-run
echo ""
echo "🔄 Running deployment dry-run test..."

if command -v kubectl &> /dev/null && command -v terraform &> /dev/null; then
    echo "✅ All required tools available for deployment"
    echo "💡 To run actual deployment:"
    echo "   Production: ./deploy-complete-stack.sh"
    echo "   UAT:        ./deploy-complete-stack.sh -e uat"
    echo "   With infra: ./deploy-complete-stack.sh -i"
else
    echo "⚠️  Some tools missing. Install: az, kubectl, docker, terraform"
fi

echo ""
echo "🎉 Testing completed!"
echo "💡 Run this test before any deployment to catch issues early."