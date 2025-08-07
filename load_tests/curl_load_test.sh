#!/bin/bash

# BIDR Backend Load Testing Script using cURL
# Simple concurrent testing with bash and curl

# Configuration
BASE_URL="http://localhost:8067"
RESULTS_DIR="load_tests/results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create results directory
mkdir -p $RESULTS_DIR

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to test an endpoint with concurrent requests
test_endpoint() {
    local endpoint=$1
    local method=$2
    local data=$3
    local concurrent_users=$4
    local requests_per_user=$5
    local test_name=$6
    
    print_status "Starting $test_name"
    print_status "Endpoint: $method $endpoint"
    print_status "Concurrent Users: $concurrent_users"
    print_status "Requests per User: $requests_per_user"
    
    local total_requests=$((concurrent_users * requests_per_user))
    local results_file="$RESULTS_DIR/${test_name// /_}_${TIMESTAMP}.txt"
    
    # Clear results file
    > $results_file
    
    # Start time
    local start_time=$(date +%s.%N)
    
    # Run concurrent requests
    for ((i=1; i<=concurrent_users; i++)); do
        (
            for ((j=1; j<=requests_per_user; j++)); do
                local request_start=$(date +%s.%N)
                
                if [ "$method" = "POST" ]; then
                    response=$(curl -s -w "%{http_code},%{time_total}" \
                        -X POST \
                        -H "Content-Type: application/json" \
                        -d "$data" \
                        "$BASE_URL$endpoint" 2>/dev/null)
                else
                    response=$(curl -s -w "%{http_code},%{time_total}" \
                        -X "$method" \
                        -H "Content-Type: application/json" \
                        "$BASE_URL$endpoint" 2>/dev/null)
                fi
                
                local request_end=$(date +%s.%N)
                local request_time=$(echo "$request_end - $request_start" | bc -l)
                
                # Extract status code and curl time
                local status_code=$(echo "$response" | tail -c 11 | cut -d',' -f1)
                local curl_time=$(echo "$response" | tail -c 11 | cut -d',' -f2)
                
                # Write result to file
                echo "$(date '+%Y-%m-%d %H:%M:%S'),$status_code,$curl_time,$endpoint,$method,User-$i,Request-$j" >> $results_file
            done
        ) &
    done
    
    # Wait for all background processes to complete
    wait
    
    # End time
    local end_time=$(date +%s.%N)
    local total_time=$(echo "$end_time - $start_time" | bc -l)
    
    # Analyze results
    analyze_results $results_file $total_requests $total_time "$test_name"
}

# Function to analyze results from file
analyze_results() {
    local results_file=$1
    local total_requests=$2
    local total_time=$3
    local test_name=$4
    
    if [ ! -f "$results_file" ]; then
        print_error "Results file not found: $results_file"
        return
    fi
    
    local successful_requests=$(awk -F',' '$2 >= 200 && $2 < 400 { count++ } END { print count+0 }' $results_file)
    local failed_requests=$(awk -F',' '$2 < 200 || $2 >= 400 { count++ } END { print count+0 }' $results_file)
    local success_rate=$(echo "scale=2; $successful_requests * 100 / $total_requests" | bc -l)
    
    # Response time statistics (only for successful requests)
    local avg_response_time=$(awk -F',' '$2 >= 200 && $2 < 400 { sum += $3; count++ } END { if (count > 0) print sum/count; else print 0 }' $results_file)
    local max_response_time=$(awk -F',' '$2 >= 200 && $2 < 400 { if ($3 > max) max = $3 } END { print max+0 }' $results_file)
    local min_response_time=$(awk -F',' '$2 >= 200 && $2 < 400 { if (min == "" || $3 < min) min = $3 } END { print min+0 }' $results_file)
    
    # Throughput
    local throughput=$(echo "scale=2; $successful_requests / $total_time" | bc -l)
    
    # Status code distribution
    local status_200=$(awk -F',' '$2 == 200 { count++ } END { print count+0 }' $results_file)
    local status_201=$(awk -F',' '$2 == 201 { count++ } END { print count+0 }' $results_file)
    local status_400=$(awk -F',' '$2 >= 400 && $2 < 500 { count++ } END { print count+0 }' $results_file)
    local status_500=$(awk -F',' '$2 >= 500 { count++ } END { print count+0 }' $results_file)
    
    # Print results
    echo
    echo "═══════════════════════════════════════════════════════════"
    echo "📊 RESULTS: $test_name"
    echo "═══════════════════════════════════════════════════════════"
    echo "Total Requests: $total_requests"
    echo "Successful Requests: $successful_requests"
    echo "Failed Requests: $failed_requests"
    echo "Success Rate: $success_rate%"
    echo "Total Test Time: $(printf "%.3f" $total_time) seconds"
    echo
    echo "Response Time Statistics (seconds):"
    echo "  Average: $(printf "%.3f" $avg_response_time)"
    echo "  Maximum: $(printf "%.3f" $max_response_time)"
    echo "  Minimum: $(printf "%.3f" $min_response_time)"
    echo
    echo "Throughput: $throughput requests/second"
    echo
    echo "Status Code Distribution:"
    echo "  200: $status_200"
    echo "  201: $status_201"
    echo "  4xx: $status_400"
    echo "  5xx: $status_500"
    echo
    
    # Save summary
    local summary_file="$RESULTS_DIR/summary_${TIMESTAMP}.txt"
    {
        echo "=== $test_name ==="
        echo "Total: $total_requests, Success: $successful_requests, Failed: $failed_requests"
        echo "Success Rate: $success_rate%, Throughput: $throughput req/s"
        echo "Avg Response Time: $(printf "%.3f" $avg_response_time)s"
        echo
    } >> $summary_file
}

# Function to check if server is running
check_server() {
    print_status "Checking if server is running..."
    response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/admin/" 2>/dev/null || echo "000")
    
    if [ "$response" = "000" ]; then
        print_error "Server is not running or not accessible at $BASE_URL"
        print_error "Please start the Django server with: python manage.py runserver 8067"
        exit 1
    else
        print_success "Server is running and accessible"
    fi
}

# Main test execution
main() {
    echo "🎯 BIDR Backend Load Testing Suite (cURL-based)"
    echo "================================================"
    echo "Start Time: $(date)"
    echo "Results will be saved in: $RESULTS_DIR"
    echo
    
    # Check if server is running
    check_server
    
    # Test 1: Admin Access - Light Load
    test_endpoint "/admin/" "GET" '' 10 20 "Admin Light Load"
    
    # Test 2: Admin Access - Heavy Load  
    test_endpoint "/admin/" "GET" '' 25 30 "Admin Heavy Load"
    
    # Test 3: API Endpoints - Light Load
    test_endpoint "/accounts/" "GET" '' 8 25 "Accounts Light Load"
    
    # Test 4: API Endpoints - Heavy Load
    test_endpoint "/accounts/" "GET" '' 20 25 "Accounts Heavy Load"
    
    echo
    echo "🎉 Load Testing Complete!"
    echo "End Time: $(date)"
    echo "Check detailed results in: $RESULTS_DIR"
    
    # Display final summary
    if [ -f "$RESULTS_DIR/summary_${TIMESTAMP}.txt" ]; then
        echo
        echo "📋 FINAL SUMMARY"
        echo "=================="
        cat "$RESULTS_DIR/summary_${TIMESTAMP}.txt"
    fi
}

# Run main function
main "$@"
