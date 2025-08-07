#!/usr/bin/env python3
"""
Load testing script for BIDR Backend using Python requests and concurrent.futures
"""

import requests
import time
import json
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from typing import List, Dict, Any
import statistics

@dataclass
class LoadTestResult:
    status_code: int
    response_time: float
    endpoint: str
    success: bool
    error_message: str = ""

class BIDRLoadTester:
    def __init__(self, base_url: str = "http://localhost:8067"):
        self.base_url = base_url
        self.session = requests.Session()
        self.results: List[LoadTestResult] = []
        
    def test_endpoint(self, endpoint: str, method: str = "GET", data: Dict[Any, Any] = None, headers: Dict[str, str] = None) -> LoadTestResult:
        """Test a single endpoint"""
        url = f"{self.base_url}{endpoint}"
        start_time = time.time()
        
        try:
            if headers is None:
                headers = {"Content-Type": "application/json"}
                
            if method.upper() == "POST":
                response = self.session.post(url, json=data, headers=headers, timeout=30)
            elif method.upper() == "GET":
                response = self.session.get(url, headers=headers, timeout=30)
            else:
                response = self.session.request(method, url, json=data, headers=headers, timeout=30)
                
            response_time = time.time() - start_time
            
            return LoadTestResult(
                status_code=response.status_code,
                response_time=response_time,
                endpoint=endpoint,
                success=response.status_code < 400,
                error_message=""
            )
            
        except Exception as e:
            response_time = time.time() - start_time
            return LoadTestResult(
                status_code=0,
                response_time=response_time,
                endpoint=endpoint,
                success=False,
                error_message=str(e)
            )
    
    def run_concurrent_test(self, endpoint: str, method: str = "GET", data: Dict[Any, Any] = None, 
                          concurrent_users: int = 10, requests_per_user: int = 10) -> List[LoadTestResult]:
        """Run concurrent load test"""
        print(f"Starting load test: {concurrent_users} concurrent users, {requests_per_user} requests each")
        print(f"Target endpoint: {method} {endpoint}")
        print("-" * 80)
        
        results = []
        
        with ThreadPoolExecutor(max_workers=concurrent_users) as executor:
            futures = []
            
            # Submit all requests
            for user in range(concurrent_users):
                for req in range(requests_per_user):
                    future = executor.submit(self.test_endpoint, endpoint, method, data)
                    futures.append(future)
            
            # Collect results
            completed = 0
            for future in as_completed(futures):
                result = future.result()
                results.append(result)
                completed += 1
                
                if completed % 10 == 0:
                    print(f"Completed: {completed}/{len(futures)} requests")
        
        return results
    
    def print_statistics(self, results: List[LoadTestResult]):
        """Print detailed statistics"""
        if not results:
            print("No results to analyze")
            return
            
        successful_results = [r for r in results if r.success]
        failed_results = [r for r in results if not r.success]
        
        response_times = [r.response_time for r in successful_results]
        
        print("\n" + "="*80)
        print("LOAD TEST RESULTS")
        print("="*80)
        
        print(f"Total Requests: {len(results)}")
        print(f"Successful: {len(successful_results)} ({len(successful_results)/len(results)*100:.1f}%)")
        print(f"Failed: {len(failed_results)} ({len(failed_results)/len(results)*100:.1f}%)")
        
        if response_times:
            print(f"\nResponse Time Statistics (seconds):")
            print(f"  Average: {statistics.mean(response_times):.3f}")
            print(f"  Median: {statistics.median(response_times):.3f}")
            print(f"  Min: {min(response_times):.3f}")
            print(f"  Max: {max(response_times):.3f}")
            print(f"  95th Percentile: {statistics.quantiles(response_times, n=20)[18]:.3f}")
            print(f"  99th Percentile: {statistics.quantiles(response_times, n=100)[98]:.3f}")
        
        # Status code breakdown
        status_codes = {}
        for result in results:
            status_codes[result.status_code] = status_codes.get(result.status_code, 0) + 1
        
        print(f"\nStatus Code Breakdown:")
        for code, count in sorted(status_codes.items()):
            print(f"  {code}: {count} requests")
        
        # Error breakdown
        if failed_results:
            print(f"\nError Messages:")
            error_counts = {}
            for result in failed_results:
                error_counts[result.error_message] = error_counts.get(result.error_message, 0) + 1
            
            for error, count in error_counts.items():
                print(f"  {error}: {count} occurrences")
        
        # Throughput calculation
        if successful_results:
            total_time = max(r.response_time for r in results)
            throughput = len(successful_results) / total_time if total_time > 0 else 0
            print(f"\nThroughput: {throughput:.2f} requests/second")

def main():
    """Main function to run load tests"""
    tester = BIDRLoadTester()
    
    # Test scenarios
    test_scenarios = [
        {
            "name": "Admin Interface",
            "endpoint": "/admin/",
            "method": "GET",
            "data": None,
            "concurrent_users": 20,
            "requests_per_user": 25
        },
        {
            "name": "Accounts Endpoint", 
            "endpoint": "/accounts/",
            "method": "GET",
            "data": None,
            "concurrent_users": 15,
            "requests_per_user": 20
        },
        {
            "name": "User Registration",
            "endpoint": "/app_user_create/",
            "method": "POST",
            "data": {"username": "newuser", "email": "test@example.com"},
            "concurrent_users": 10,
            "requests_per_user": 30
        }
    ]
    
    all_results = {}
    
    for scenario in test_scenarios:
        print(f"\n{'='*20} {scenario['name']} {'='*20}")
        
        results = tester.run_concurrent_test(
            endpoint=scenario["endpoint"],
            method=scenario["method"],
            data=scenario["data"],
            concurrent_users=scenario["concurrent_users"],
            requests_per_user=scenario["requests_per_user"]
        )
        
        all_results[scenario["name"]] = results
        tester.print_statistics(results)
        
        # Wait between scenarios
        time.sleep(2)
    
    # Overall summary
    print(f"\n{'='*20} OVERALL SUMMARY {'='*20}")
    total_requests = sum(len(results) for results in all_results.values())
    total_successful = sum(len([r for r in results if r.success]) for results in all_results.values())
    
    print(f"Total Requests Across All Scenarios: {total_requests}")
    print(f"Overall Success Rate: {total_successful/total_requests*100:.1f}%")

if __name__ == "__main__":
    main()
