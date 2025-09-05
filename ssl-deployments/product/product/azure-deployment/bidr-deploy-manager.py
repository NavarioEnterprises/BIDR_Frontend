#!/usr/bin/env python3

"""
BIDR Deployment Manager
An interactive terminal script for managing BIDR microservices deployment on Azure
"""

import os
import sys
import subprocess
import json
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import time

# ANSI color codes for terminal output
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

class BIDRDeploymentManager:
    def __init__(self):
        self.current_dir = Path(__file__).parent
        self.base_dir = self.current_dir.parent.parent
        
        # Service configurations
        self.services = {
            "1": {
                "name": "Product Management Service",
                "service_key": "product",
                "directory": "product_management_service",
                "port": 8000,
                "container_name": "bidr-product-service",
                "icon": "📦",
                "script": "deploy-product-service.sh",
                "update_script": "update-product-service.sh"
            },
            "2": {
                "name": "Authentication Service",
                "service_key": "auth",
                "directory": "authentication_service",
                "port": 8001,
                "container_name": "bidr-auth-service",
                "icon": "🔐",
                "script": "deploy-auth-service.sh",
                "update_script": "update-auth-service.sh"
            },
            "3": {
                "name": "Chat Service",
                "service_key": "chat",
                "directory": "chat_service",
                "port": 8002,
                "container_name": "bidr-chat-service",
                "icon": "💬",
                "script": "deploy-chat-service.sh",
                "update_script": "update-chat-service.sh"
            },
            "4": {
                "name": "Payment Service",
                "service_key": "payment",
                "directory": "payment_service",
                "port": 8003,
                "container_name": "bidr-payment-service",
                "icon": "💳",
                "script": "deploy-payment-service.sh",
                "update_script": "update-payment-service.sh"
            },
            "5": {
                "name": "Resolution Service",
                "service_key": "resolution",
                "directory": "resolution_service",
                "port": 8004,
                "container_name": "bidr-resolution-service",
                "icon": "⚖️",
                "script": "deploy-resolution-service.sh",
                "update_script": "update-resolution-service.sh"
            },
            "6": {
                "name": "Notifications Service",
                "service_key": "notifications",
                "directory": "notifications_service",
                "port": 8005,
                "container_name": "bidr-notifications-service",
                "icon": "🔔",
                "script": "deploy-notifications-service.sh",
                "update_script": "update-notifications-service.sh"
            },
            "7": {
                "name": "Transactions Service",
                "service_key": "transactions",
                "directory": "transactions_service",
                "port": 8006,
                "container_name": "bidr-transactions-service",
                "icon": "💰",
                "script": "deploy-transactions-service.sh",
                "update_script": "update-transactions-service.sh"
            },
            "8": {
                "name": "Reviews Service",
                "service_key": "reviews",
                "directory": "reviews_and_ratings",
                "port": 8007,
                "container_name": "bidr-reviews-service",
                "icon": "⭐",
                "script": "deploy-reviews-service.sh",
                "update_script": "update-reviews-service.sh"
            }
        }

    def print_header(self):
        """Print the application header"""
        print(f"\n{Colors.HEADER}{'=' * 60}{Colors.ENDC}")
        print(f"{Colors.HEADER}{Colors.BOLD}🚀 BIDR Deployment Manager{Colors.ENDC}")
        print(f"{Colors.BLUE}Interactive Azure Microservices Deployment Tool{Colors.ENDC}")
        print(f"{Colors.HEADER}{'=' * 60}{Colors.ENDC}\n")

    def print_menu(self):
        """Print the main menu"""
        print(f"{Colors.CYAN}{Colors.BOLD}📋 Available Actions:{Colors.ENDC}")
        print(f"{Colors.YELLOW}1. Deploy/Update Individual Service{Colors.ENDC}")
        print(f"{Colors.YELLOW}2. Update All Services{Colors.ENDC}")
        print(f"{Colors.YELLOW}3. Check Services Status{Colors.ENDC}")
        print(f"{Colors.YELLOW}4. Build Container Only (No Deploy){Colors.ENDC}")
        print(f"{Colors.YELLOW}5. Create New Update Scripts{Colors.ENDC}")
        print(f"{Colors.RED}6. Exit{Colors.ENDC}")
        print()

    def print_services_menu(self):
        """Print the services selection menu"""
        print(f"\n{Colors.CYAN}{Colors.BOLD}🎯 Available BIDR Services:{Colors.ENDC}")
        print(f"{Colors.HEADER}{'─' * 50}{Colors.ENDC}")
        
        for key, service in self.services.items():
            status_icon = self.get_service_status_icon(service['container_name'])
            print(f"{Colors.YELLOW}{key}. {service['icon']} {service['name']} {status_icon}{Colors.ENDC}")
            suggested_path = self.base_dir / service['directory']
            print(f"   {Colors.BLUE}Path: {suggested_path}{Colors.ENDC}")
            print(f"   {Colors.GREEN}Port: {service['port']} | Container: {service['container_name']}{Colors.ENDC}")
            print()
        
        print(f"{Colors.YELLOW}9. {Colors.BOLD}All Services{Colors.ENDC}")
        print(f"{Colors.RED}0. Back to Main Menu{Colors.ENDC}\n")

    def get_service_status_icon(self, container_name: str) -> str:
        """Get status icon for a service"""
        try:
            result = subprocess.run([
                'az', 'container', 'show',
                '--resource-group', 'bidr-simple-rg',
                '--name', container_name,
                '--query', 'instanceView.state',
                '--output', 'tsv'
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0 and result.stdout.strip() == 'Running':
                return f"{Colors.GREEN}✅{Colors.ENDC}"
            elif result.returncode == 0:
                return f"{Colors.YELLOW}⚠️{Colors.ENDC}"
            else:
                return f"{Colors.RED}❌{Colors.ENDC}"
        except:
            return f"{Colors.RED}❓{Colors.ENDC}"

    def validate_path(self, path: str) -> Tuple[bool, str]:
        """Validate if the path exists and has required files"""
        path_obj = Path(path).expanduser().resolve()
        
        if not path_obj.exists():
            return False, f"Path does not exist: {path_obj}"
        
        if not path_obj.is_dir():
            return False, f"Path is not a directory: {path_obj}"
        
        dockerfile = path_obj / "Dockerfile"
        if not dockerfile.exists():
            return False, f"Dockerfile not found in: {path_obj}"
        
        return True, str(path_obj)

    def get_service_path(self, service: Dict) -> Optional[str]:
        """Get and validate service path from user input"""
        suggested_path = self.base_dir / service['directory']
        
        print(f"\n{Colors.CYAN}📁 Service Path Configuration:{Colors.ENDC}")
        print(f"{Colors.BLUE}Suggested path: {Colors.BOLD}{suggested_path}{Colors.ENDC}")
        
        choice = input(f"{Colors.YELLOW}Use suggested path? [Y/n]: {Colors.ENDC}").strip().lower()
        
        if choice in ['', 'y', 'yes']:
            path = str(suggested_path)
        else:
            path = input(f"{Colors.YELLOW}Enter custom path: {Colors.ENDC}").strip()
            if not path:
                print(f"{Colors.RED}❌ No path provided{Colors.ENDC}")
                return None
        
        valid, resolved_path = self.validate_path(path)
        if not valid:
            print(f"{Colors.RED}❌ {resolved_path}{Colors.ENDC}")
            return None
        
        print(f"{Colors.GREEN}✅ Using path: {resolved_path}{Colors.ENDC}")
        return resolved_path

    def build_container(self, service: Dict, service_path: str) -> bool:
        """Build container for the service"""
        print(f"\n{Colors.BLUE}🔨 Building container for {service['name']}...{Colors.ENDC}")
        
        try:
            # Change to service directory
            original_dir = os.getcwd()
            os.chdir(service_path)
            
            # Build with Azure Container Registry
            cmd = [
                'az', 'acr', 'build',
                '--registry', 'bidrsimpleregistry',
                '--image', f"bidr-{service['service_key']}-service:latest",
                '.'
            ]
            
            print(f"{Colors.YELLOW}Executing: {' '.join(cmd)}{Colors.ENDC}")
            
            result = subprocess.run(cmd, check=False)
            
            os.chdir(original_dir)
            
            if result.returncode == 0:
                print(f"{Colors.GREEN}✅ Container built successfully!{Colors.ENDC}")
                return True
            else:
                print(f"{Colors.RED}❌ Container build failed with return code {result.returncode}{Colors.ENDC}")
                return False
                
        except subprocess.SubprocessError as e:
            print(f"{Colors.RED}❌ Build error: {str(e)}{Colors.ENDC}")
            return False
        except Exception as e:
            print(f"{Colors.RED}❌ Unexpected error: {str(e)}{Colors.ENDC}")
            return False
        finally:
            os.chdir(original_dir)

    def execute_deployment_script(self, script_name: str) -> bool:
        """Execute a deployment script"""
        script_path = self.current_dir / script_name
        
        if not script_path.exists():
            print(f"{Colors.RED}❌ Script not found: {script_path}{Colors.ENDC}")
            return False
        
        print(f"\n{Colors.BLUE}🚀 Executing deployment script: {script_name}{Colors.ENDC}")
        
        try:
            # Make script executable
            os.chmod(script_path, 0o755)
            
            # Execute script
            result = subprocess.run([str(script_path)], cwd=self.current_dir, check=False)
            
            if result.returncode == 0:
                print(f"{Colors.GREEN}✅ Deployment completed successfully!{Colors.ENDC}")
                return True
            else:
                print(f"{Colors.RED}❌ Deployment failed with return code {result.returncode}{Colors.ENDC}")
                return False
                
        except Exception as e:
            print(f"{Colors.RED}❌ Deployment error: {str(e)}{Colors.ENDC}")
            return False

    def deploy_service(self, service: Dict, update_mode: bool = False):
        """Deploy or update a single service"""
        print(f"\n{Colors.HEADER}{'=' * 50}{Colors.ENDC}")
        print(f"{Colors.BOLD}{service['icon']} {'Updating' if update_mode else 'Deploying'} {service['name']}{Colors.ENDC}")
        print(f"{Colors.HEADER}{'=' * 50}{Colors.ENDC}")
        
        # Get service path
        service_path = self.get_service_path(service)
        if not service_path:
            return False
        
        # Ask for build confirmation
        build_choice = input(f"\n{Colors.YELLOW}🔨 Build new container? [Y/n]: {Colors.ENDC}").strip().lower()
        
        if build_choice in ['', 'y', 'yes']:
            if not self.build_container(service, service_path):
                print(f"{Colors.RED}❌ Aborting deployment due to build failure{Colors.ENDC}")
                return False
            
            print(f"{Colors.GREEN}✅ Container built successfully!{Colors.ENDC}")
        
        # Ask for deployment confirmation
        script_name = service['update_script'] if update_mode else service['script']
        deploy_choice = input(f"\n{Colors.YELLOW}🚀 Execute deployment script ({script_name})? [Y/n]: {Colors.ENDC}").strip().lower()
        
        if deploy_choice in ['', 'y', 'yes']:
            return self.execute_deployment_script(script_name)
        else:
            print(f"{Colors.BLUE}ℹ️  Skipping deployment as requested{Colors.ENDC}")
            return True

    def deploy_all_services(self):
        """Deploy all services"""
        print(f"\n{Colors.HEADER}{'=' * 50}{Colors.ENDC}")
        print(f"{Colors.BOLD}🚀 Deploying All BIDR Services{Colors.ENDC}")
        print(f"{Colors.HEADER}{'=' * 50}{Colors.ENDC}")
        
        confirm = input(f"\n{Colors.YELLOW}⚠️  This will update ALL services. Continue? [y/N]: {Colors.ENDC}").strip().lower()
        
        if confirm not in ['y', 'yes']:
            print(f"{Colors.BLUE}ℹ️  Operation cancelled{Colors.ENDC}")
            return
        
        return self.execute_deployment_script("update-all-services.sh")

    def check_services_status(self):
        """Check status of all services"""
        print(f"\n{Colors.BLUE}🔍 Checking BIDR Services Status...{Colors.ENDC}")
        
        status_script = self.current_dir / "check-services-status.sh"
        if not status_script.exists():
            print(f"{Colors.RED}❌ Status script not found: {status_script}{Colors.ENDC}")
            return
        
        try:
            subprocess.run([str(status_script)], cwd=self.current_dir, check=True)
        except subprocess.CalledProcessError as e:
            print(f"{Colors.RED}❌ Status check failed: {str(e)}{Colors.ENDC}")
        except Exception as e:
            print(f"{Colors.RED}❌ Unexpected error: {str(e)}{Colors.ENDC}")

    def build_only_mode(self):
        """Build containers without deploying"""
        print(f"\n{Colors.CYAN}🔨 Container Build Mode{Colors.ENDC}")
        
        while True:
            self.print_services_menu()
            choice = input(f"{Colors.YELLOW}Select service to build (0-9): {Colors.ENDC}").strip()
            
            if choice == '0':
                return
            elif choice == '9':
                # Build all services
                confirm = input(f"\n{Colors.YELLOW}Build containers for ALL services? [y/N]: {Colors.ENDC}").strip().lower()
                if confirm in ['y', 'yes']:
                    for service in self.services.values():
                        service_path = self.get_service_path(service)
                        if service_path:
                            self.build_container(service, service_path)
                        print()
                return
            elif choice in self.services:
                service = self.services[choice]
                service_path = self.get_service_path(service)
                if service_path:
                    self.build_container(service, service_path)
            else:
                print(f"{Colors.RED}❌ Invalid choice. Please try again.{Colors.ENDC}")

    def create_missing_scripts(self):
        """Create any missing deployment scripts"""
        print(f"\n{Colors.BLUE}🔧 Checking for missing deployment scripts...{Colors.ENDC}")
        
        missing_scripts = []
        for service in self.services.values():
            deploy_script = self.current_dir / service['script']
            update_script = self.current_dir / service['update_script']
            
            if not deploy_script.exists():
                missing_scripts.append(('deploy', service, deploy_script))
            if not update_script.exists():
                missing_scripts.append(('update', service, update_script))
        
        if not missing_scripts:
            print(f"{Colors.GREEN}✅ All deployment scripts exist!{Colors.ENDC}")
            return
        
        print(f"{Colors.YELLOW}Found {len(missing_scripts)} missing scripts:{Colors.ENDC}")
        for script_type, service, path in missing_scripts:
            print(f"  - {script_type} script for {service['name']}: {path.name}")
        
        create = input(f"\n{Colors.YELLOW}Create missing scripts? [Y/n]: {Colors.ENDC}").strip().lower()
        if create in ['', 'y', 'yes']:
            print(f"{Colors.BLUE}ℹ️  Script creation feature coming soon!{Colors.ENDC}")
            print(f"{Colors.BLUE}ℹ️  For now, you can copy existing scripts and modify them{Colors.ENDC}")

    def run(self):
        """Main application loop"""
        try:
            while True:
                self.print_header()
                self.print_menu()
                
                choice = input(f"{Colors.YELLOW}Select an action (1-6): {Colors.ENDC}").strip()
                
                if choice == '1':
                    # Deploy/Update Individual Service
                    while True:
                        self.print_services_menu()
                        service_choice = input(f"{Colors.YELLOW}Select service (0-9): {Colors.ENDC}").strip()
                        
                        if service_choice == '0':
                            break
                        elif service_choice == '9':
                            self.deploy_all_services()
                            break
                        elif service_choice in self.services:
                            service = self.services[service_choice]
                            
                            # Ask if this is an update or new deployment
                            update_mode = input(f"\n{Colors.YELLOW}Is this an update? [Y/n]: {Colors.ENDC}").strip().lower()
                            is_update = update_mode in ['', 'y', 'yes']
                            
                            self.deploy_service(service, update_mode=is_update)
                            break
                        else:
                            print(f"{Colors.RED}❌ Invalid choice. Please try again.{Colors.ENDC}")
                
                elif choice == '2':
                    # Update All Services
                    self.deploy_all_services()
                
                elif choice == '3':
                    # Check Services Status
                    self.check_services_status()
                
                elif choice == '4':
                    # Build Container Only
                    self.build_only_mode()
                
                elif choice == '5':
                    # Create New Update Scripts
                    self.create_missing_scripts()
                
                elif choice == '6':
                    # Exit
                    print(f"\n{Colors.GREEN}👋 Thank you for using BIDR Deployment Manager!{Colors.ENDC}")
                    print(f"{Colors.BLUE}Your BIDR platform is running strong! 🚀{Colors.ENDC}\n")
                    sys.exit(0)
                
                else:
                    print(f"{Colors.RED}❌ Invalid choice. Please try again.{Colors.ENDC}")
                
                # Pause before showing menu again
                input(f"\n{Colors.CYAN}Press Enter to continue...{Colors.ENDC}")
                
        except KeyboardInterrupt:
            print(f"\n\n{Colors.YELLOW}🛑 Operation cancelled by user{Colors.ENDC}")
            print(f"{Colors.GREEN}👋 Goodbye!{Colors.ENDC}\n")
            sys.exit(0)
        except Exception as e:
            print(f"\n{Colors.RED}❌ Unexpected error: {str(e)}{Colors.ENDC}")
            sys.exit(1)

if __name__ == "__main__":
    # Check prerequisites
    try:
        subprocess.run(['az', '--version'], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print(f"{Colors.RED}❌ Azure CLI not found. Please install Azure CLI first.{Colors.ENDC}")
        print(f"{Colors.BLUE}Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli{Colors.ENDC}")
        sys.exit(1)
    
    try:
        subprocess.run(['docker', '--version'], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print(f"{Colors.RED}❌ Docker not found. Please install Docker first.{Colors.ENDC}")
        print(f"{Colors.BLUE}Visit: https://docs.docker.com/get-docker/{Colors.ENDC}")
        sys.exit(1)
    
    # Run the application
    manager = BIDRDeploymentManager()
    manager.run()
