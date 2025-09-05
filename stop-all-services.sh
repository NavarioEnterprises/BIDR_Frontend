#!/bin/bash

# BIDR Backend - Stop All Local Services Script

set -e

echo "🛑 Stopping BIDR Backend Services..."

# Define service ports
PORTS=(8001 8002 8003 8004 8005 8006 8007 8008)
SERVICE_NAMES=("Authentication" "Chat" "Payment" "Resolution" "Products" "Notifications" "Transactions" "Reviews")

# Function to kill process on port
kill_port() {
    local port=$1
    local service_name=$2
    local pid=$(lsof -ti:$port 2>/dev/null || true)
    if [ ! -z "$pid" ]; then
        echo "🛑 Stopping $service_name on port $port (PID: $pid)"
        kill -15 $pid 2>/dev/null || true
        sleep 2
        
        # Force kill if still running
        local still_running=$(lsof -ti:$port 2>/dev/null || true)
        if [ ! -z "$still_running" ]; then
            echo "💀 Force stopping $service_name on port $port"
            kill -9 $still_running 2>/dev/null || true
        fi
        echo "✅ $service_name stopped"
    else
        echo "✅ No process running on port $port"
    fi
}

# Stop all services
for i in "${!PORTS[@]}"; do
    kill_port "${PORTS[$i]}" "${SERVICE_NAMES[$i]}"
done

echo ""
echo "🧹 Cleaning up log files (keeping last 1000 lines)..."
for log_file in *.log; do
    if [ -f "$log_file" ]; then
        tail -n 1000 "$log_file" > "${log_file}.tmp" && mv "${log_file}.tmp" "$log_file"
        echo "📝 Trimmed $log_file"
    fi
done

echo ""
echo "✅ All BIDR Backend services have been stopped!"
echo ""
echo "💡 To start services again, run: ./run-all-services.sh"