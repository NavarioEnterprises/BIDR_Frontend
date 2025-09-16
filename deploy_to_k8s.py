#!/usr/bin/env python3
"""
BIDR Kubernetes Deployment Manager
==================================

This script helps deploy local code changes to the Kubernetes cluster.
It provides options to update all services or individual services.

Author: BIDR Team
Usage: python deploy_to_k8s.py
"""

import os
import sys
import subprocess
import json
from datetime import datetime
from pathlib import Path

class BIDRDeploymentManager:
    def __init__(self):
        self.script_dir = Path(__file__).parent
        self.project_root = self.script_dir
        self.namespace = "bidr"
        
        # Service configurations
        self.services = {
            "auth": {
                "name": "auth-service",
                "local_path": self.project_root / "authentication_service",
                "deployment_file": self.project_root / "k8s/overlays/uat/auth-service.yaml",
                "description": "Authentication Service - User management and authentication"
            },
            "products": {
                "name": "product-management-service", 
                "local_path": self.project_root / "product_management_service",
                "deployment_file": self.project_root / "k8s/overlays/uat/product-django-real.yaml",
                "description": "Product Management Service - Products and inventory"
            },
            "reviews": {
                "name": "reviews-service",
                "local_path": self.project_root / "reviews_and_ratings",
                "deployment_file": self.project_root / "k8s/overlays/uat/reviews-service-real.yaml", 
                "description": "Reviews and Ratings Service - User reviews and ratings"
            },
            "chat": {
                "name": "chat-service",
                "local_path": self.project_root / "chat_service",
                "deployment_file": self.project_root / "k8s/overlays/uat/chat-service-real.yaml",
                "description": "Chat Service - Real-time messaging with WebSocket support"
            },
            "payments": {
                "name": "payment-service",
                "local_path": self.project_root / "payment_service", 
                "deployment_file": self.project_root / "k8s/overlays/uat/payment-service-real.yaml",
                "description": "Payment Service - Secure payment processing with Stripe/PayPal integration"
            },
            "notifications": {
                "name": "notifications-service",
                "local_path": self.project_root / "notifications_service",
                "deployment_file": self.project_root / "k8s/overlays/uat/notifications-service-real.yaml",
                "description": "Notifications Service - Email, SMS, and push notification system with Celery"
            },
            "resolution": {
                "name": "resolution-service",
                "local_path": self.project_root / "resolution_service", 
                "deployment_file": self.project_root / "k8s/overlays/uat/resolution-service-real.yaml",
                "description": "Resolution Service - Dispute resolution with mediation/arbitration workflow"
            },
            "nginx": {
                "name": "nginx-proxy",
                "local_path": self.project_root / "nginx",
                "deployment_file": None,  # Special handling for nginx
                "description": "Nginx Reverse Proxy - Load balancer and routing"
            }
        }
        
        # Scripts directory
        self.scripts_dir = self.project_root / "nginx"
        
    def print_header(self):
        """Print the application header"""
        print("=" * 60)
        print("🚀 BIDR Kubernetes Deployment Manager")
        print("=" * 60)
        print(f"📁 Project Root: {self.project_root}")
        print(f"🔧 Namespace: {self.namespace}")
        print(f"📅 Current Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 60)
        print()
        
    def check_prerequisites(self):
        """Check if required tools are available"""
        print("🔍 Checking prerequisites...")
        
        # Update PATH to include Homebrew binaries
        if "/opt/homebrew/bin" not in os.environ.get("PATH", ""):
            os.environ["PATH"] = f"/opt/homebrew/bin:{os.environ.get('PATH', '')}"
        
        required_tools = ["kubectl", "docker"]
        missing_tools = []
        
        for tool in required_tools:
            try:
                if tool == "kubectl":
                    subprocess.run([tool, "version", "--client"], capture_output=True, check=True)
                else:
                    subprocess.run([tool, "--version"], capture_output=True, check=True)
                print(f"  ✅ {tool} - Available")
            except (subprocess.CalledProcessError, FileNotFoundError):
                print(f"  ❌ {tool} - Not found")
                missing_tools.append(tool)
        
        if missing_tools:
            print(f"\n❌ Missing required tools: {', '.join(missing_tools)}")
            print("Please install the missing tools and try again.")
            return False
            
        # Check kubectl connection
        try:
            result = subprocess.run(
                ["kubectl", "cluster-info"], 
                capture_output=True, 
                check=True, 
                text=True
            )
            print("  ✅ Kubernetes cluster - Connected")
        except subprocess.CalledProcessError:
            print("  ❌ Kubernetes cluster - Not connected")
            print("Please check your kubectl configuration and cluster connection.")
            return False
            
        print("✅ All prerequisites met!\n")
        return True
        
    def list_services(self):
        """List all available services"""
        print("📋 Available Services:")
        print("-" * 60)
        
        for i, (key, service) in enumerate(self.services.items(), 1):
            status = "✅" if service["local_path"].exists() else "❌"
            print(f"{i:2d}. {status} {service['name']}")
            print(f"     {service['description']}")
            print(f"     📁 {service['local_path']}")
            print()
            
    def get_service_status(self, service_key):
        """Get the current status of a service in Kubernetes"""
        service = self.services[service_key]
        
        try:
            result = subprocess.run([
                "kubectl", "get", "deployment", service["name"], 
                "-n", self.namespace, "-o", "json"
            ], capture_output=True, check=True, text=True)
            
            deployment_info = json.loads(result.stdout)
            replicas = deployment_info["spec"]["replicas"]
            ready_replicas = deployment_info["status"].get("readyReplicas", 0)
            
            return f"Running ({ready_replicas}/{replicas})"
            
        except subprocess.CalledProcessError:
            return "Not Found"
            
    def show_service_menu(self):
        """Show service selection menu"""
        print("🎯 Service Selection:")
        print("-" * 60)
        
        # Add option to update all services
        print("  0. 🌟 UPDATE ALL SERVICES")
        print()
        
        for i, (key, service) in enumerate(self.services.items(), 1):
            status = self.get_service_status(key)
            local_status = "✅" if service["local_path"].exists() else "❌"
            print(f"{i:2d}. {local_status} {service['name']:<25} [{status}]")
            
        print()
        print("99. 🚪 Exit")
        print("-" * 60)
        
    def backup_current_deployment(self, service_key):
        """Backup current deployment configuration"""
        service = self.services[service_key]
        backup_dir = self.project_root / "backups" / f"deployment-{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        backup_dir.mkdir(parents=True, exist_ok=True)
        
        print(f"📥 Backing up current {service['name']} deployment...")
        
        try:
            backup_file = backup_dir / f"{service_key}-deployment.yaml"
            with open(backup_file, 'w') as f:
                subprocess.run([
                    "kubectl", "get", "deployment", service["name"],
                    "-n", self.namespace, "-o", "yaml"
                ], stdout=f, check=True)
                
            print(f"✅ Backup saved to: {backup_file}")
            return backup_file
            
        except subprocess.CalledProcessError as e:
            print(f"⚠️  Backup failed: {e}")
            return None
            
    def deploy_service(self, service_key):
        """Deploy a specific service"""
        service = self.services[service_key]
        
        print(f"\n🚀 Deploying {service['name']}...")
        print("-" * 40)
        
        # Check if local path exists
        if not service["local_path"].exists():
            print(f"❌ Local service directory not found: {service['local_path']}")
            return False
            
        # Backup current deployment
        backup_file = self.backup_current_deployment(service_key)
        
        # Handle nginx separately
        if service_key == "nginx":
            return self.deploy_nginx()
            
        # Apply deployment
        if service["deployment_file"] and service["deployment_file"].exists():
            try:
                print(f"📦 Applying deployment file: {service['deployment_file']}")
                subprocess.run([
                    "kubectl", "apply", "-f", str(service["deployment_file"])
                ], check=True)
                
                print(f"✅ Deployment file applied successfully")
                
                # Restart the deployment to pick up changes
                print(f"🔄 Restarting deployment...")
                subprocess.run([
                    "kubectl", "rollout", "restart", "deployment", service["name"],
                    "-n", self.namespace
                ], check=True)
                
                # Wait for rollout
                print(f"⏳ Waiting for rollout to complete...")
                subprocess.run([
                    "kubectl", "rollout", "status", "deployment", service["name"],
                    "-n", self.namespace, "--timeout=300s"
                ], check=True)
                
                print(f"✅ {service['name']} deployed successfully!")
                return True
                
            except subprocess.CalledProcessError as e:
                print(f"❌ Deployment failed: {e}")
                
                if backup_file:
                    print(f"🔄 Restoring from backup...")
                    try:
                        subprocess.run(["kubectl", "apply", "-f", str(backup_file)], check=True)
                        print(f"✅ Restored from backup")
                    except subprocess.CalledProcessError:
                        print(f"❌ Restore from backup also failed")
                        
                return False
        else:
            print(f"❌ Deployment file not found: {service['deployment_file']}")
            return False
            
    def deploy_nginx(self):
        """Deploy nginx configuration using existing scripts"""
        print("🌐 Deploying nginx configuration...")
        
        # Check if nginx scripts exist
        scripts = [
            self.scripts_dir / "backup-nginx-config.sh",
            self.scripts_dir / "apply-django-url-prefixes.sh"
        ]
        
        for script in scripts:
            if not script.exists():
                print(f"❌ Required script not found: {script}")
                return False
                
        try:
            # Backup current nginx config
            print("📥 Backing up current nginx configuration...")
            subprocess.run([str(scripts[0])], cwd=self.scripts_dir, check=True)
            
            # Apply new configuration
            print("🚀 Applying nginx configuration with Django URL prefixes...")
            process = subprocess.run([
                "bash", "-c", f"echo 'y' | {scripts[1]}"
            ], cwd=self.scripts_dir, check=True, capture_output=True, text=True)
            
            print("✅ Nginx configuration deployed successfully!")
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"❌ Nginx deployment failed: {e}")
            if e.stdout:
                print(f"Output: {e.stdout}")
            if e.stderr:
                print(f"Error: {e.stderr}")
            return False
            
    def deploy_all_services(self):
        """Deploy all services"""
        print("\n🌟 Deploying ALL services...")
        print("=" * 60)
        
        success_count = 0
        total_count = len(self.services)
        
        for service_key in self.services.keys():
            print(f"\n📦 Processing {service_key}...")
            if self.deploy_service(service_key):
                success_count += 1
                print(f"✅ {service_key} - SUCCESS")
            else:
                print(f"❌ {service_key} - FAILED")
                
        print("\n" + "=" * 60)
        print(f"📊 Deployment Summary: {success_count}/{total_count} services deployed successfully")
        
        if success_count == total_count:
            print("🎉 All services deployed successfully!")
        elif success_count > 0:
            print("⚠️  Some services failed to deploy. Check the logs above.")
        else:
            print("❌ All deployments failed. Please check your configuration.")
            
    def show_deployment_status(self):
        """Show current deployment status"""
        print("\n📊 Current Deployment Status:")
        print("-" * 60)
        
        for service_key, service in self.services.items():
            status = self.get_service_status(service_key)
            local_exists = "✅" if service["local_path"].exists() else "❌"
            print(f"{local_exists} {service['name']:<25} - {status}")
            
    def main_menu(self):
        """Main application menu"""
        while True:
            try:
                self.show_service_menu()
                
                choice = input("\n🎯 Select service to deploy (0 for all, 99 to exit): ").strip()
                
                if choice == "99":
                    print("\n👋 Goodbye!")
                    break
                    
                elif choice == "0":
                    confirm = input("\n⚠️  Are you sure you want to deploy ALL services? (y/N): ").strip().lower()
                    if confirm == 'y':
                        self.deploy_all_services()
                    else:
                        print("Deployment cancelled.")
                        
                elif choice.isdigit():
                    choice_num = int(choice)
                    if 1 <= choice_num <= len(self.services):
                        service_key = list(self.services.keys())[choice_num - 1]
                        service_name = self.services[service_key]["name"]
                        
                        confirm = input(f"\n🚀 Deploy {service_name}? (y/N): ").strip().lower()
                        if confirm == 'y':
                            self.deploy_service(service_key)
                        else:
                            print("Deployment cancelled.")
                    else:
                        print("❌ Invalid choice. Please try again.")
                else:
                    print("❌ Invalid input. Please enter a number.")
                    
                # Show status after each operation
                self.show_deployment_status()
                
                input("\n📋 Press Enter to continue...")
                print("\n" + "="*60 + "\n")
                
            except KeyboardInterrupt:
                print("\n\n👋 Deployment cancelled by user. Goodbye!")
                break
            except Exception as e:
                print(f"\n❌ An error occurred: {e}")
                input("\n📋 Press Enter to continue...")
                
    def run(self):
        """Main application entry point"""
        try:
            self.print_header()
            
            if not self.check_prerequisites():
                return 1
                
            self.list_services()
            self.main_menu()
            
            return 0
            
        except Exception as e:
            print(f"\n❌ Fatal error: {e}")
            return 1

if __name__ == "__main__":
    manager = BIDRDeploymentManager()
    sys.exit(manager.run())