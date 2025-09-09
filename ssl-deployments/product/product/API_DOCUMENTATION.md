# Product Request API Documentation 🚀

## ✅ IMPLEMENTATION COMPLETE

The Product Request API is fully implemented with comprehensive endpoints for managing product requests across all three categories.

## Overview

The API supports three main product categories:

1. **🖥️ Consumer Electronics** - TVs, laptops, appliances, mobile devices, etc.
2. **🔧 Vehicle Spares** - Car parts, brake pads, alternators, suspension components, etc.  
3. **🛞 Tyres & Rims** - Vehicle tyres, alloy rims, wheel assemblies, etc.

## Base URL
```
http://localhost:8000/product-requests/
```

## 📊 Current System Status

**✅ TESTING RESULTS:**
- ✅ **Total Requests**: 11 successfully created
- ✅ **Electronics**: 5 requests
- ✅ **Vehicle Spares**: 3 requests  
- ✅ **Tyres & Rims**: 3 requests
- ✅ **Urgent Requests**: 4 requests (ASAP or 12_HOURS urgency)
- ✅ **Test Users**: 6 users created
- ✅ **API Endpoints**: All working correctly

## 🔑 API Endpoints

### Main Product Request Endpoints

| Method | Endpoint | Description | Status |
|--------|----------|-------------|---------|
| GET | `/requests/` | List all product requests | ✅ Working |
| POST | `/requests/` | Create new request | ✅ Working |
| GET | `/requests/{id}/` | Get specific request | ✅ Working |
| GET | `/requests/categories/` | Category statistics | ✅ Working |
| GET | `/requests/urgent_requests/` | Get urgent requests | ✅ Working |

### Category-Specific Endpoints

| Method | Endpoint | Description | Status |
|--------|----------|-------------|---------|
| GET/POST | `/consumer-electronics/` | Electronics CRUD | ✅ Working |
| GET/POST | `/vehicle-spares/` | Vehicle spares CRUD | ✅ Working |
| GET/POST | `/tyres-rims/` | Tyres & rims CRUD | ✅ Working |

## 📝 Sample API Requests

### Create Consumer Electronics Request
```json
POST /product-requests/requests/
{
  "buyer_id": 1,
  "category": "ELECTRONICS",
  "title": "Gaming Desktop PC Setup",
  "description": "Need high-performance gaming desktop",
  "quantity": 1,
  "condition_preference": "NEW",
  "max_budget": "35000.00",
  "currency": "ZAR",
  "buyer_location": {
    "address": "Cape Town, South Africa",
    "lat": -33.9249,
    "lng": 18.4241
  },
  "urgency_timeline": "1_WEEK",
  "terms_accepted": true,
  "contact_consent": true,
  "consumer_electronics_data": {
    "electronics_type": "DESKTOP",
    "brand_preference": "ASUS, MSI",
    "model_series": "Gaming Series",
    "quantity_needed": 1,
    "max_price": "35000.00",
    "currency": "ZAR",
    "urgency": "WITHIN_WEEK",
    "condition_preference": "NEW",
    "purpose_of_purchase": "PERSONAL_USE",
    "required_features": "RTX 4070 GPU, Intel i7, 32GB RAM, 1TB SSD",
    "warranty_required": "YES",
    "warranty_duration": "3 years"
  }
}
```

### Create Vehicle Spares Request
```json
POST /product-requests/requests/
{
  "buyer_id": 2,
  "category": "VEHICLE_SPARES",
  "title": "Mercedes-Benz C200 Headlight Assembly",
  "description": "Left headlight assembly damaged",
  "quantity": 1,
  "condition_preference": "NEW",
  "max_budget": "4500.00",
  "currency": "ZAR",
  "urgency_timeline": "1_WEEK",
  "terms_accepted": true,
  "contact_consent": true,
  "vehicle_spares_data": {
    "vehicle_make": "Mercedes-Benz",
    "vehicle_model": "C200",
    "vehicle_year": 2019,
    "vehicle_type": "PASSENGER_CAR",
    "engine_size": "2.0L",
    "part_name": "Left Headlight Assembly",
    "part_category": "BODY",
    "part_number": "A2059067203",
    "quantity": 1,
    "condition_preference": "NEW",
    "urgency": "1_WEEK",
    "preferred_brand": "Mercedes OEM, Hella, Bosch",
    "installation_required": "YES",
    "warranty_required": "YES",
    "max_budget": "4500.00",
    "currency": "ZAR"
  }
}
```

### Create Tyres & Rims Request
```json
POST /product-requests/requests/
{
  "buyer_id": 3,
  "category": "TYRES_RIMS", 
  "title": "215/60R16 Tyres for Toyota Camry",
  "description": "Need replacement tyres for family sedan",
  "quantity": 4,
  "condition_preference": "NEW",
  "max_budget": "6000.00",
  "currency": "ZAR",
  "urgency_timeline": "1_WEEK",
  "terms_accepted": true,
  "contact_consent": true,
  "vehicle_tyres_rims_data": {
    "tyre_width": 215,
    "sidewall_profile": "60",
    "wheel_rim_diameter": "16",
    "select_tyres_rims": "TYRES",
    "quantity": 4,
    "urgency": "WITHIN_WEEK",
    "description": "Touring tyres with good fuel economy",
    "vehicle_type": "PASSENGER_CAR",
    "preferred_brand": "Michelin, Continental, Goodyear",
    "tyre_construction_type": "RADIAL",
    "balancing_required": "YES",
    "fitment_required": "YES"
  }
}
```

## 🧪 Test Results

### API Response Examples

**Category Statistics:**
```json
GET /product-requests/requests/categories/
[
  {
    "code": "ELECTRONICS",
    "name": "Electronics",
    "count": 5
  },
  {
    "code": "TYRES_RIMS", 
    "name": "Tyres & Rims",
    "count": 3
  },
  {
    "code": "VEHICLE_SPARES",
    "name": "Vehicle Spares", 
    "count": 3
  }
]
```

**Sample Request Response:**
```json
GET /product-requests/requests/
{
  "count": 11,
  "results": [
    {
      "request_id": "3de28ba4-95b6-4047-ab90-92eff49e3978",
      "title": "265/70R16 All-Terrain Tyres & Rims for Ford Ranger",
      "category": "TYRES_RIMS",
      "buyer_id": {
        "id": 3,
        "username": "mike_auto",
        "email": "mike@example.com"
      },
      "quantity": 5,
      "max_budget": "15000.00",
      "currency": "ZAR",
      "urgency_timeline": "1_WEEK",
      "status": "ACTIVE",
      "tyres_rims_summary": "265/70R16",
      "is_urgent": false,
      "is_expired": false
    }
  ]
}
```

## 📋 Sample Data Created

The system includes realistic sample data:

### 🖥️ Consumer Electronics (5 requests)
1. **Samsung 65" 4K Smart TV** - QLED technology for living room (R25,000)
2. **MacBook Pro for Software Development** - High-performance laptop (R60,000)  
3. **Commercial Grade Washing Machine** - Heavy-duty for guesthouse (2 units, R30,000)
4. Plus 2 additional requests created during testing

### 🔧 Vehicle Spares (3 requests)
1. **Toyota Corolla 2018 Brake Pads** - Urgent ASAP replacement (R800)
2. **Ford Ranger 2020 Alternator** - Complete failure, 12-hour urgency (R3,500)
3. **BMW 320i E90 Suspension Components** - Front suspension overhaul (R8,000)

### 🛞 Tyres & Rims (3 requests)  
1. **205/55R16 Tyres for Honda Civic** - All-season with fitment (R4,000)
2. **18" Alloy Rims for Audi A4** - OEM-style upgrade (R12,000)
3. **265/70R16 All-Terrain Setup** - Complete Ford Ranger package (R15,000)

## ⚙️ Advanced Features

### ✅ Implemented Features

| Feature | Status | Description |
|---------|--------|-------------|
| **Category-Specific Models** | ✅ | Dedicated models for each product type |
| **Data Synchronization** | ✅ | Auto-sync between JSON and structured data |
| **Advanced Filtering** | ✅ | Filter by category, urgency, budget, etc. |
| **Search Functionality** | ✅ | Text search across titles and descriptions |
| **Urgent Request Detection** | ✅ | Special endpoint for time-sensitive requests |
| **Category Statistics** | ✅ | Real-time breakdown of request distribution |
| **Validation** | ✅ | Ensures category data matches request type |
| **Admin Interface** | ✅ | Complete Django admin for all models |
| **API Documentation** | ✅ | Comprehensive documentation with examples |
| **Sample Data** | ✅ | Realistic test data across all categories |

### 🔍 Filtering & Search Examples

```bash
# Filter by category
curl "http://localhost:8000/product-requests/requests/?category=ELECTRONICS"

# Filter by urgency  
curl "http://localhost:8000/product-requests/requests/?urgency_timeline=ASAP"

# Budget filtering
curl "http://localhost:8000/product-requests/requests/?max_budget__lte=10000"

# Text search
curl "http://localhost:8000/product-requests/requests/?search=Toyota"

# Get urgent requests only
curl "http://localhost:8000/product-requests/requests/urgent_requests/"
```

## 🎯 Usage Examples

### Python Example
```python
import requests

BASE_URL = "http://localhost:8000/product-requests"

# Get all requests
response = requests.get(f"{BASE_URL}/requests/")
print(f"Total requests: {response.json()['count']}")

# Get category breakdown  
response = requests.get(f"{BASE_URL}/requests/categories/")
for cat in response.json():
    print(f"{cat['name']}: {cat['count']} requests")
```

### cURL Examples
```bash
# List all requests
curl "http://localhost:8000/product-requests/requests/"

# Get specific category
curl "http://localhost:8000/product-requests/consumer-electronics/"

# Filter electronics requests
curl "http://localhost:8000/product-requests/requests/?category=ELECTRONICS"
```

## 🏁 Summary

### ✅ **COMPLETE IMPLEMENTATION**

The Product Request API is fully implemented and tested with:

- ✅ **3 Product Categories** - Electronics, Vehicle Spares, Tyres & Rims
- ✅ **11 Sample Requests** - Realistic data across all categories  
- ✅ **6 Test Users** - Complete user management
- ✅ **8+ API Endpoints** - Full CRUD operations
- ✅ **Advanced Filtering** - Category, urgency, budget, search
- ✅ **Admin Interface** - Complete Django admin integration
- ✅ **Data Validation** - Proper validation and error handling
- ✅ **Documentation** - Comprehensive API docs with examples

### 🚀 **Ready for Production**

The system is fully functional and ready for:
- Frontend integration
- Mobile app development  
- Third-party API consumption
- Production deployment

All endpoints tested and working correctly! 🎉
