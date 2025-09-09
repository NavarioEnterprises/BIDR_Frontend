#!/usr/bin/env python3

"""
Script to add django-prometheus configuration to all BIDR services
"""

import os
import re

# Base directory
BASE_DIR = "/Users/thulanimoyo/MEGA downloads/new downloads/BIDR_Backend"

# Services to update (excluding auth which is already done)
SERVICES = [
    "chat_service",
    "payment_service",
    "resolution_service", 
    "product_management_service",
    "notifications_service",
    "transactions_service",
    "reviews_and_ratings"
]

def add_prometheus_to_service(service_name):
    """Add django-prometheus to a service's settings and URLs"""
    
    # Find settings.py file
    service_dir = os.path.join(BASE_DIR, service_name)
    settings_patterns = [
        f"{service_name}/settings.py",
        f"{service_name.replace('_', '')}/settings.py",
        "settings.py"
    ]
    
    settings_file = None
    urls_file = None
    
    # Find settings file
    for pattern in settings_patterns:
        potential_path = os.path.join(service_dir, pattern)
        if os.path.exists(potential_path):
            settings_file = potential_path
            # Find corresponding urls.py
            urls_path = potential_path.replace('settings.py', 'urls.py')
            if os.path.exists(urls_path):
                urls_file = urls_path
            break
    
    if not settings_file:
        print(f"❌ Could not find settings.py for {service_name}")
        return False
    
    print(f"📝 Updating {service_name}...")
    print(f"   Settings: {settings_file}")
    print(f"   URLs: {urls_file}")
    
    # Update settings.py
    update_settings(settings_file)
    
    # Update urls.py if found
    if urls_file:
        update_urls(urls_file)
    else:
        print(f"   ⚠️  URLs file not found for {service_name}")
    
    return True

def update_settings(settings_file):
    """Update settings.py to add django-prometheus"""
    
    with open(settings_file, 'r') as f:
        content = f.read()
    
    # Check if django_prometheus is already added
    if 'django_prometheus' in content:
        print("   ✅ django-prometheus already configured in settings")
        return
    
    # Add to INSTALLED_APPS
    installed_apps_pattern = r"INSTALLED_APPS\s*=\s*\[(.*?)\]"
    match = re.search(installed_apps_pattern, content, re.DOTALL)
    
    if match:
        # Find a good place to add django_prometheus
        apps_content = match.group(1)
        
        # Add to third-party apps section if exists
        if "'corsheaders'" in apps_content:
            content = content.replace("'corsheaders',", "'corsheaders',\n    'django_prometheus',")
        elif "'rest_framework'" in apps_content:
            content = content.replace("'rest_framework',", "'rest_framework',\n    'django_prometheus',")
        else:
            # Add at the end of INSTALLED_APPS
            content = content.replace(apps_content, apps_content.rstrip() + "\n    'django_prometheus',\n")
    
    # Add middleware
    middleware_pattern = r"MIDDLEWARE\s*=\s*\[(.*?)\]"
    match = re.search(middleware_pattern, content, re.DOTALL)
    
    if match:
        middleware_content = match.group(1)
        
        # Add PrometheusBeforeMiddleware at the beginning
        first_middleware = re.search(r"'([^']+)'", middleware_content)
        if first_middleware:
            first_mw = first_middleware.group(0)
            content = content.replace(
                first_mw,
                "'django_prometheus.middleware.PrometheusBeforeMiddleware',\n    " + first_mw
            )
        
        # Add PrometheusAfterMiddleware at the end
        content = content.replace(
            middleware_content.rstrip(),
            middleware_content.rstrip() + "\n    'django_prometheus.middleware.PrometheusAfterMiddleware',"
        )
    
    # Write back
    with open(settings_file, 'w') as f:
        f.write(content)
    
    print("   ✅ Updated settings.py")

def update_urls(urls_file):
    """Update urls.py to add metrics endpoint"""
    
    with open(urls_file, 'r') as f:
        content = f.read()
    
    # Check if metrics is already added
    if 'django_prometheus.urls' in content:
        print("   ✅ Metrics endpoint already configured in URLs")
        return
    
    # Add metrics path to urlpatterns
    if "path('health/'," in content:
        # Add after health endpoint
        content = content.replace(
            "path('health/',",
            "path('health/',\n    # Metrics endpoint for Prometheus\n    path('metrics/', include('django_prometheus.urls')),\n    path('health/',"
        )
        # Fix duplicate health path
        content = content.replace(
            "path('health/',\n    # Metrics endpoint for Prometheus\n    path('metrics/', include('django_prometheus.urls')),\n    path('health/',",
            "# Metrics endpoint for Prometheus\n    path('metrics/', include('django_prometheus.urls')),\n    path('health/',"
        )
    elif "urlpatterns = [" in content:
        # Add after admin if no health endpoint
        if "path('admin/'," in content:
            content = content.replace(
                "path('admin/',",
                "path('admin/',\n    \n    # Metrics endpoint for Prometheus\n    path('metrics/', include('django_prometheus.urls')),"
            )
        else:
            # Add as first entry
            content = content.replace(
                "urlpatterns = [",
                "urlpatterns = [\n    # Metrics endpoint for Prometheus\n    path('metrics/', include('django_prometheus.urls')),"
            )
    
    # Ensure include is imported
    if "from django.urls import" in content and "include" not in content:
        content = content.replace(
            "from django.urls import path",
            "from django.urls import path, include"
        )
    
    # Write back
    with open(urls_file, 'w') as f:
        f.write(content)
    
    print("   ✅ Updated urls.py")

def main():
    print("🚀 Adding django-prometheus to all BIDR services...")
    print()
    
    success_count = 0
    
    for service in SERVICES:
        if add_prometheus_to_service(service):
            success_count += 1
        print()
    
    print(f"✅ Successfully updated {success_count}/{len(SERVICES)} services")
    print()
    print("🔄 Next steps:")
    print("1. Rebuild and restart all services")
    print("2. Check Prometheus targets at http://localhost:9090/targets")
    print("3. Check Grafana dashboards at http://localhost:3000")

if __name__ == "__main__":
    main()
