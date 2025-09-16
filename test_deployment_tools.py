#!/usr/bin/env python3
"""
Test script for BIDR deployment tools
"""

import subprocess
import sys
from pathlib import Path

def test_prerequisites():
    """Test that required tools are available"""
    print("🧪 Testing Prerequisites...")
    
    tools = {
        "kubectl": ["kubectl", "version", "--client"],
        "python": ["python3", "--version"],
        "bash": ["bash", "--version"]
    }
    
    for tool, cmd in tools.items():
        try:
            result = subprocess.run(cmd, capture_output=True, check=True, text=True)
            print(f"  ✅ {tool} - Available")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print(f"  ❌ {tool} - Not available")
            return False
    
    return True

def test_kubectl_connection():
    """Test kubectl connection to cluster"""
    print("\n🔌 Testing Kubectl Connection...")
    
    try:
        result = subprocess.run(
            ["kubectl", "cluster-info"], 
            capture_output=True, 
            check=True, 
            text=True
        )
        print("  ✅ Connected to Kubernetes cluster")
        return True
    except subprocess.CalledProcessError:
        print("  ❌ Not connected to Kubernetes cluster")
        return False

def test_file_structure():
    """Test that required files exist"""
    print("\n📁 Testing File Structure...")
    
    script_dir = Path(__file__).parent
    required_files = [
        "deploy_to_k8s.py",
        "quick_deploy.sh", 
        "DEPLOYMENT_GUIDE.md",
        "nginx/nginx-k8s.conf",
        "nginx/backup-nginx-config.sh",
        "nginx/apply-django-url-prefixes.sh",
        "k8s/overlays/uat/product-django-real.yaml",
        "k8s/overlays/uat/reviews-service-real.yaml"
    ]
    
    all_exist = True
    for file_path in required_files:
        full_path = script_dir / file_path
        if full_path.exists():
            print(f"  ✅ {file_path}")
        else:
            print(f"  ❌ {file_path} - Missing")
            all_exist = False
    
    return all_exist

def test_services_status():
    """Test current service status in cluster"""
    print("\n📊 Testing Service Status...")
    
    services = [
        "auth-service",
        "product-management-service",
        "reviews-service",
        "chat-service", 
        "payment-service",
        "notifications-service",
        "transactions-service",
        "resolution-service",
        "nginx-proxy"
    ]
    
    namespace = "bidr"
    
    for service in services:
        try:
            result = subprocess.run([
                "kubectl", "get", "deployment", service, 
                "-n", namespace, "-o", "jsonpath={.status.readyReplicas}/{.spec.replicas}"
            ], capture_output=True, check=True, text=True)
            
            status = result.stdout.strip()
            print(f"  📦 {service:<25} - {status}")
            
        except subprocess.CalledProcessError:
            print(f"  ❌ {service:<25} - Not Found")

def test_deployment_scripts():
    """Test that deployment scripts are executable"""
    print("\n🔧 Testing Script Permissions...")
    
    script_dir = Path(__file__).parent
    scripts = [
        "deploy_to_k8s.py",
        "quick_deploy.sh",
        "nginx/backup-nginx-config.sh",
        "nginx/apply-django-url-prefixes.sh"
    ]
    
    for script in scripts:
        script_path = script_dir / script
        if script_path.exists() and script_path.stat().st_mode & 0o111:
            print(f"  ✅ {script} - Executable")
        else:
            print(f"  ❌ {script} - Not executable")
            return False
    
    return True

def main():
    print("=" * 60)
    print("🧪 BIDR Deployment Tools Test")
    print("=" * 60)
    
    tests = [
        ("Prerequisites", test_prerequisites),
        ("Kubectl Connection", test_kubectl_connection), 
        ("File Structure", test_file_structure),
        ("Script Permissions", test_deployment_scripts),
        ("Services Status", test_services_status)
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        try:
            if test_func():
                passed += 1
        except Exception as e:
            print(f"  ❌ {test_name} failed with error: {e}")
    
    print("\n" + "=" * 60)
    print(f"📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! Deployment tools are ready to use.")
        print("\nNext steps:")
        print("  python deploy_to_k8s.py     # Interactive deployment")
        print("  ./quick_deploy.sh products  # Quick deployment")
        return 0
    else:
        print("⚠️  Some tests failed. Please check the issues above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())