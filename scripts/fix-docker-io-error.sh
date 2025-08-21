#!/bin/bash

# Docker I/O Error Fix Script
# This script helps resolve input/output errors in Docker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check Docker status
check_docker_status() {
    print_status "Checking Docker status..."
    
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker Desktop first."
        exit 1
    fi
    
    print_success "Docker is running"
}

# Check disk space
check_disk_space() {
    print_status "Checking disk space..."
    
    local available_space=$(df -h / | awk 'NR==2 {print $4}')
    print_status "Available disk space: $available_space"
    
    # Check if we have less than 5GB available
    local space_gb=$(df / | awk 'NR==2 {print $4}')
    if [ "$space_gb" -lt 5242880 ]; then  # 5GB in KB
        print_warning "Low disk space detected. Consider freeing up space."
    fi
}

# Clean Docker system
clean_docker_system() {
    print_status "Cleaning Docker system..."
    
    print_status "Stopping all containers..."
    docker stop $(docker ps -aq) 2>/dev/null || true
    
    print_status "Removing all containers..."
    docker rm $(docker ps -aq) 2>/dev/null || true
    
    print_status "Removing unused images..."
    docker image prune -a -f
    
    print_status "Removing unused volumes..."
    docker volume prune -f
    
    print_status "Removing unused networks..."
    docker network prune -f
    
    print_status "Running system-wide cleanup..."
    docker system prune -a -f --volumes
    
    print_success "Docker cleanup completed"
}

# Restart Docker Desktop
restart_docker() {
    print_status "Attempting to restart Docker Desktop..."
    
    if command -v osascript >/dev/null 2>&1; then
        print_status "Stopping Docker Desktop..."
        osascript -e 'quit app "Docker Desktop"' 2>/dev/null || true
        sleep 5
        
        print_status "Starting Docker Desktop..."
        open -a "Docker Desktop"
        
        print_status "Waiting for Docker to start..."
        local count=0
        while ! docker info >/dev/null 2>&1 && [ $count -lt 30 ]; do
            echo -n "."
            sleep 2
            count=$((count + 1))
        done
        echo
        
        if docker info >/dev/null 2>&1; then
            print_success "Docker Desktop restarted successfully"
        else
            print_error "Failed to restart Docker Desktop"
            return 1
        fi
    else
        print_warning "Cannot automatically restart Docker Desktop. Please restart it manually."
        return 1
    fi
}

# Check Docker Desktop settings
check_docker_settings() {
    print_status "Checking Docker Desktop settings..."
    
    # Check available memory and CPU
    local memory_info=$(docker system info 2>/dev/null | grep -E "Total Memory|CPUs" || echo "Could not retrieve system info")
    print_status "Docker system info: $memory_info"
    
    print_status "Recommended Docker Desktop settings:"
    echo "  - Memory: At least 4GB (8GB recommended)"
    echo "  - Swap: 1GB"
    echo "  - Disk image size: At least 60GB"
    echo "  - File sharing: Enable for your project directory"
}

# Test Docker functionality
test_docker() {
    print_status "Testing Docker functionality..."
    
    print_status "Testing basic Docker command..."
    if docker run --rm hello-world >/dev/null 2>&1; then
        print_success "Basic Docker functionality works"
    else
        print_error "Basic Docker functionality failed"
        return 1
    fi
    
    print_status "Testing Docker Compose..."
    if docker-compose version >/dev/null 2>&1; then
        print_success "Docker Compose is working"
    else
        print_error "Docker Compose is not working"
        return 1
    fi
}

# Fix Docker storage driver issues
fix_storage_driver() {
    print_status "Checking Docker storage driver..."
    
    local driver=$(docker info 2>/dev/null | grep "Storage Driver" | cut -d: -f2 | xargs)
    print_status "Current storage driver: $driver"
    
    if [ "$driver" = "overlay2" ]; then
        print_success "Storage driver is optimal"
    else
        print_warning "Storage driver is not overlay2. This might cause issues."
        print_status "Consider updating Docker Desktop to the latest version."
    fi
}

# Main fix function
main() {
    echo "=========================================="
    echo "Docker I/O Error Fix Script"
    echo "=========================================="
    
    case "${1:-auto}" in
        "clean")
            check_docker_status
            clean_docker_system
            ;;
            
        "restart")
            restart_docker
            ;;
            
        "check")
            check_docker_status
            check_disk_space
            check_docker_settings
            fix_storage_driver
            test_docker
            ;;
            
        "auto"|*)
            print_status "Running automatic Docker I/O error fix..."
            
            check_docker_status
            check_disk_space
            
            print_status "Step 1: Cleaning Docker system..."
            clean_docker_system
            
            print_status "Step 2: Testing Docker functionality..."
            if ! test_docker; then
                print_status "Step 3: Restarting Docker Desktop..."
                if restart_docker; then
                    print_status "Step 4: Testing again..."
                    test_docker
                fi
            fi
            
            check_docker_settings
            fix_storage_driver
            
            print_success "Docker I/O error fix completed!"
            print_status "You can now try running your Docker Compose command again."
            ;;
    esac
}

# Show usage if help requested
if [[ "$1" == "help" || "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  auto     - Run automatic fix (default)"
    echo "  clean    - Clean Docker system only"
    echo "  restart  - Restart Docker Desktop only"
    echo "  check    - Check Docker status and settings"
    echo "  help     - Show this help message"
    exit 0
fi

# Run the fix
main "$@"
