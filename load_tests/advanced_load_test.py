#!/usr/bin/env python3
"""
Advanced Load Testing Suite for BIDR Backend
Includes stress testing, spike testing, and endurance testing scenarios
"""

import requests
import time
import json
import threading
import queue
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, asdict
from typing import List, Dict, Any, Optional
import statistics
import os
from datetime import datetime
import csv

@dataclass
class TestResult:
    timestamp: str
    endpoint: str
    method: str
    status_code: int
    response_time: float
    success: bool
    error_message: str = ""
    test_phase: str = ""

class AdvancedLoadTester:
    def __init__(self, base_url: str = "http://localhost:8067"):
        self.base_url = base_url
        self.results: List[TestResult] = []
        self.session = requests.Session()
        
    def make_request(self, endpoint: str, method: str = "GET", data: Dict = None, 
                    headers: Dict = None, test_phase: str = "default") -> TestResult:
        """Make a single HTTP request and record metrics"""
        url = f"{self.base_url}{endpoint}"
        start_time = time.time()
        timestamp = datetime.now().isoformat()
        
        if headers is None:
            headers = {"Content-Type": "application/json"}
        
        try:
            if method.upper() == "POST":
                response = self.session.post(url, json=data, headers=headers, timeout=30)
            elif method.upper() == "GET":
                response = self.session.get(url, headers=headers, timeout=30)
            elif method.upper() == "PUT":
                response = self.session.put(url, json=data, headers=headers, timeout=30)
            elif method.upper() == "DELETE":
                response = self.session.delete(url, headers=headers, timeout=30)
            else:
                response = self.session.request(method, url, json=data, headers=headers, timeout=30)
            
            response_time = time.time() - start_time
            
            return TestResult(
                timestamp=timestamp,
                endpoint=endpoint,
                method=method,
                status_code=response.status_code,
                response_time=response_time,
                success=response.status_code < 400,
                test_phase=test_phase
            )
            
        except Exception as e:
            response_time = time.time() - start_time
            return TestResult(
                timestamp=timestamp,
                endpoint=endpoint,
                method=method,
                status_code=0,
                response_time=response_time,
                success=False,
                error_message=str(e),
                test_phase=test_phase
            )
    
    def baseline_test(self, endpoint: str, method: str = "GET", data: Dict = None, 
                     duration: int = 60, concurrent_users: int = 5) -> List[TestResult]:
        """Baseline performance test - steady load for duration"""
        print(f"🔄 Starting Baseline Test: {method} {endpoint}")
        print(f"   Duration: {duration}s, Concurrent Users: {concurrent_users}")
        
        results = []
        start_time = time.time()
        
        def worker():
            while time.time() - start_time < duration:
                result = self.make_request(endpoint, method, data, test_phase="baseline")
                results.append(result)
                time.sleep(0.1)  # Small delay between requests
        
        threads = []
        for _ in range(concurrent_users):
            thread = threading.Thread(target=worker)
            thread.start()
            threads.append(thread)
        
        for thread in threads:
            thread.join()
        
        print(f"   ✅ Completed: {len(results)} requests")
        return results
    
    def stress_test(self, endpoint: str, method: str = "GET", data: Dict = None,
                   max_users: int = 50, ramp_up_time: int = 30) -> List[TestResult]:
        """Stress test - gradually increase load to find breaking point"""
        print(f"🚀 Starting Stress Test: {method} {endpoint}")
        print(f"   Max Users: {max_users}, Ramp-up Time: {ramp_up_time}s")
        
        results = []
        user_increment = max_users // 10
        
        for current_users in range(user_increment, max_users + 1, user_increment):
            print(f"   📈 Ramping up to {current_users} users...")
            
            with ThreadPoolExecutor(max_workers=current_users) as executor:
                futures = []
                for _ in range(current_users * 10):  # 10 requests per user
                    future = executor.submit(self.make_request, endpoint, method, data, test_phase=f"stress_{current_users}")
                    futures.append(future)
                
                for future in as_completed(futures):
                    result = future.result()
                    results.append(result)
            
            time.sleep(2)  # Brief pause between ramp-ups
        
        print(f"   ✅ Completed: {len(results)} requests")
        return results
    
    def spike_test(self, endpoint: str, method: str = "GET", data: Dict = None,
                  spike_users: int = 100, spike_duration: int = 10) -> List[TestResult]:
        """Spike test - sudden surge of traffic"""
        print(f"⚡ Starting Spike Test: {method} {endpoint}")
        print(f"   Spike Users: {spike_users}, Duration: {spike_duration}s")
        
        results = []
        start_time = time.time()
        
        def spike_worker():
            while time.time() - start_time < spike_duration:
                result = self.make_request(endpoint, method, data, test_phase="spike")
                results.append(result)
        
        threads = []
        for _ in range(spike_users):
            thread = threading.Thread(target=spike_worker)
            thread.start()
            threads.append(thread)
        
        for thread in threads:
            thread.join()
        
        print(f"   ✅ Completed: {len(results)} requests")
        return results
    
    def endurance_test(self, endpoint: str, method: str = "GET", data: Dict = None,
                      duration: int = 300, concurrent_users: int = 10) -> List[TestResult]:
        """Endurance test - sustained load over extended period"""
        print(f"⏱️  Starting Endurance Test: {method} {endpoint}")
        print(f"   Duration: {duration}s ({duration//60}min), Users: {concurrent_users}")
        
        results = []
        start_time = time.time()
        
        def endurance_worker():
            while time.time() - start_time < duration:
                result = self.make_request(endpoint, method, data, test_phase="endurance")
                results.append(result)
                time.sleep(0.5)  # Moderate pacing for endurance
        
        threads = []
        for _ in range(concurrent_users):
            thread = threading.Thread(target=endurance_worker)
            thread.start()
            threads.append(thread)
        
        for thread in threads:
            thread.join()
        
        print(f"   ✅ Completed: {len(results)} requests")
        return results
    
    def analyze_results(self, results: List[TestResult]) -> Dict[str, Any]:
        """Analyze test results and generate statistics"""
        if not results:
            return {"error": "No results to analyze"}
        
        successful_results = [r for r in results if r.success]
        failed_results = [r for r in results if not r.success]
        
        response_times = [r.response_time for r in successful_results]
        
        # Group by test phase
        phases = {}
        for result in results:
            phase = result.test_phase
            if phase not in phases:
                phases[phase] = []
            phases[phase].append(result)
        
        # Status code distribution
        status_codes = {}
        for result in results:
            code = result.status_code
            status_codes[code] = status_codes.get(code, 0) + 1
        
        analysis = {
            "total_requests": len(results),
            "successful_requests": len(successful_results),
            "failed_requests": len(failed_results),
            "success_rate": len(successful_results) / len(results) * 100 if results else 0,
            "status_code_distribution": status_codes,
            "phases": {}
        }
        
        if response_times:
            analysis.update({
                "response_time_stats": {
                    "mean": statistics.mean(response_times),
                    "median": statistics.median(response_times),
                    "min": min(response_times),
                    "max": max(response_times),
                    "std_dev": statistics.stdev(response_times) if len(response_times) > 1 else 0,
                    "percentile_95": statistics.quantiles(response_times, n=20)[18] if len(response_times) > 19 else max(response_times),
                    "percentile_99": statistics.quantiles(response_times, n=100)[98] if len(response_times) > 99 else max(response_times)
                }
            })
        
        # Analyze each phase
        for phase, phase_results in phases.items():
            phase_successful = [r for r in phase_results if r.success]
            phase_response_times = [r.response_time for r in phase_successful]
            
            phase_analysis = {
                "total_requests": len(phase_results),
                "successful_requests": len(phase_successful),
                "success_rate": len(phase_successful) / len(phase_results) * 100 if phase_results else 0
            }
            
            if phase_response_times:
                phase_analysis["avg_response_time"] = statistics.mean(phase_response_times)
                phase_analysis["max_response_time"] = max(phase_response_times)
            
            analysis["phases"][phase] = phase_analysis
        
        return analysis
    
    def save_results_csv(self, results: List[TestResult], filename: str):
        """Save detailed results to CSV file"""
        os.makedirs(os.path.dirname(filename), exist_ok=True)
        
        with open(filename, 'w', newline='') as csvfile:
            fieldnames = ['timestamp', 'endpoint', 'method', 'status_code', 
                         'response_time', 'success', 'error_message', 'test_phase']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            
            writer.writeheader()
            for result in results:
                writer.writerow(asdict(result))
        
        print(f"📊 Detailed results saved to: {filename}")

def main():
    """Run comprehensive load testing suite"""
    tester = AdvancedLoadTester()
    all_results = []
    
    # Test endpoints configuration
    endpoints = [
        {
            "endpoint": "/admin/",
            "method": "GET",
            "data": None,
            "name": "Admin Interface"
        },
        {
            "endpoint": "/accounts/",
            "method": "GET", 
            "data": None,
            "name": "Accounts Endpoint"
        }
    ]
    
    print("🎯 Starting Comprehensive Load Testing Suite for BIDR")
    print("=" * 60)
    
    for endpoint_config in endpoints:
        endpoint = endpoint_config["endpoint"]
        method = endpoint_config["method"]
        data = endpoint_config["data"]
        name = endpoint_config["name"]
        
        print(f"\n🔧 Testing {name}")
        print("-" * 40)
        
        # Run different test types
        try:
            # Baseline Test
            baseline_results = tester.baseline_test(endpoint, method, data, duration=30, concurrent_users=5)
            all_results.extend(baseline_results)
            
            # Stress Test
            stress_results = tester.stress_test(endpoint, method, data, max_users=30, ramp_up_time=20)
            all_results.extend(stress_results)
            
            # Spike Test
            spike_results = tester.spike_test(endpoint, method, data, spike_users=50, spike_duration=5)
            all_results.extend(spike_results)
            
            # Short Endurance Test (reduced for demo)
            endurance_results = tester.endurance_test(endpoint, method, data, duration=60, concurrent_users=8)
            all_results.extend(endurance_results)
            
        except Exception as e:
            print(f"❌ Error testing {name}: {e}")
        
        time.sleep(2)  # Brief pause between endpoint tests
    
    print(f"\n📊 Analyzing {len(all_results)} total requests...")
    
    # Analyze all results
    analysis = tester.analyze_results(all_results)
    
    # Save results
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    csv_filename = f"load_tests/advanced_results_{timestamp}.csv"
    tester.save_results_csv(all_results, csv_filename)
    
    return analysis, all_results

if __name__ == "__main__":
    analysis, results = main()
    
    # Print summary
    print("\n" + "=" * 60)
    print("🎯 COMPREHENSIVE LOAD TEST SUMMARY")
    print("=" * 60)
    print(f"Total Requests: {analysis['total_requests']}")
    print(f"Success Rate: {analysis['success_rate']:.1f}%")
    if 'response_time_stats' in analysis:
        stats = analysis['response_time_stats']
        print(f"Average Response Time: {stats['mean']:.3f}s")
        print(f"95th Percentile: {stats['percentile_95']:.3f}s")
        print(f"99th Percentile: {stats['percentile_99']:.3f}s")
