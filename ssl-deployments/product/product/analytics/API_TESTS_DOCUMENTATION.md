# Analytics API Testing Documentation

This document provides comprehensive testing instructions for all analytics API endpoints, including request/response examples and expected behaviors.

## Authentication

All analytics endpoints require authentication. Include the following header in all requests:
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

## Base URL

All analytics API endpoints are prefixed with:
```
https://your-domain.com/analytics/api/v1/
```

---

## 1. Product Request Analytics API

### List Product Request Analytics

**Endpoint:** `GET /product-request-analytics/`

**Description:** Retrieve a paginated list of product request analytics.

**Query Parameters:**
- `timeframe` (string): Filter by timeframe (hourly, daily, weekly, monthly, quarterly, yearly)
- `date` (date): Filter by specific date
- `request__category` (string): Filter by product request category
- `request__status` (string): Filter by product request status
- `ordering` (string): Order by field (e.g., -date, views, supplier_interest_score)
- `search` (string): Search in request title/description

**Example Request:**
```bash
curl -X GET "https://your-domain.com/analytics/api/v1/product-request-analytics/?timeframe=daily&ordering=-views" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Example Response:**
```json
{
  "count": 25,
  "next": "https://your-domain.com/analytics/api/v1/product-request-analytics/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "request": 123,
      "request_details": {
        "request_id": "3de28ba4-95b6-4047-ab90-92eff49e3978",
        "title": "Gaming Laptop Request",
        "category": "CONSUMER_ELECTRONICS"
      },
      "date": "2025-08-09",
      "timeframe": "daily",
      "views": 150,
      "unique_views": 120,
      "search_appearances": 25,
      "search_clicks": 18,
      "quote_responses": 8,
      "messages_sent": 5,
      "watchlist_additions": 12,
      "average_response_time": "02:30:00",
      "supplier_interest_score": "85.50",
      "click_through_rate": "72.00",
      "response_rate": "5.33",
      "created_at": "2025-08-09T10:00:00Z",
      "updated_at": "2025-08-09T15:30:00Z"
    }
  ]
}
```

### Get Product Request Analytics Detail

**Endpoint:** `GET /product-request-analytics/{id}/`

**Example Request:**
```bash
curl -X GET "https://your-domain.com/analytics/api/v1/product-request-analytics/1/" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Create Product Request Analytics

**Endpoint:** `POST /product-request-analytics/`

**Example Request:**
```bash
curl -X POST "https://your-domain.com/analytics/api/v1/product-request-analytics/" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "request": 123,
    "date": "2025-08-09",
    "timeframe": "daily",
    "views": 100,
    "unique_views": 80,
    "supplier_interest_score": "75.00"
  }'
```

### Update Product Request Analytics

**Endpoint:** `PUT /product-request-analytics/{id}/`

**Example Request:**
```bash
curl -X PUT "https://your-domain.com/analytics/api/v1/product-request-analytics/1/" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "views": 150,
    "unique_views": 120,
    "supplier_interest_score": "85.00"
  }'
```

### Delete Product Request Analytics

**Endpoint:** `DELETE /product-request-analytics/{id}/`

### Get Top Performing Requests

**Endpoint:** `GET /product-request-analytics/top_performing_requests/`

**Query Parameters:**
- `timeframe` (string): Time period (daily, weekly, monthly)
- `limit` (integer): Number of results (default: 10)
- `metric` (string): Metric to sort by (views, quote_responses, supplier_interest_score)

**Example Request:**
```bash
curl -X GET "https://your-domain.com/analytics/api/v1/product-request-analytics/top_performing_requests/?metric=views&limit=5&timeframe=weekly" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Example Response:**
```json
[
  {
    "id": 1,
    "request": 123,
    "request_details": {
      "request_id": "3de28ba4-95b6-4047-ab90-92eff49e3978",
      "title": "Gaming Laptop Request",
      "category": "CONSUMER_ELECTRONICS"
    },
    "views": 500,
    "quote_responses": 25,
    "supplier_interest_score": "92.50"
  }
]
```

### Get Category Performance Summary

**Endpoint:** `GET /product-request-analytics/category_performance/`

**Example Request:**
```bash
curl -X GET "https://your-domain.com/analytics/api/v1/product-request-analytics/category_performance/?timeframe=monthly" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Example Response:**
```json
[
  {
    "request__category__name": "Consumer Electronics",
    "total_views": 2500,
    "total_quotes": 125,
    "avg_interest_score": 78.25,
    "request_count": 50
  },
  {
    "request__category__name": "Vehicle Spares",
    "total_views": 1800,
    "total_quotes": 90,
    "avg_interest_score": 72.10,
    "request_count": 35
  }
]
```

---

## 2. Category Analytics API

### List Category Analytics

**Endpoint:** `GET /category-analytics/`

**Example Request:**
```bash
curl -X GET "https://your-domain.com/analytics/api/v1/category-analytics/?timeframe=daily&ordering=-total_revenue" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Example Response:**
```json
{
  "count": 10,
  "results": [
    {
      "id": 1,
      "category": 5,
      "category_details": {
        "name": "Consumer Electronics",
        "description": "Electronics category"
      },
      "date": "2025-08-09",
      "timeframe": "daily",
      "total_requests": 45,
      "active_requests": 38,
      "new_requests": 8,
      "closed_requests": 7,
      "total_views": 2200,
      "total_quote_requests": 180,
      "total_quotes": 145,
      "total_orders": 35,
      "total_revenue": "85000.00",
      "average_price": "2430.00",
      "average_rating": "4.65"
    }
  ]
}
```

### Get Top Categories

**Endpoint:** `GET /category-analytics/top_categories/`

**Query Parameters:**
- `timeframe` (string): Time period (daily, weekly, monthly)
- `limit` (integer): Number of results (default: 10)
- `metric` (string): Metric to sort by (total_requests, total_revenue, total_views)

**Example Request:**
```bash
curl -X GET "https://your-domain.com/analytics/api/v1/category-analytics/top_categories/?metric=total_revenue&limit=5" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 3. User Behavior Analytics API

### List User Behavior Analytics

**Endpoint:** `GET /user-behavior-analytics/`

**Example Request:**
```bash
curl -X GET "https://your-domain.com/analytics/api/v1/user-behavior-analytics/?timeframe=daily" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Example Response:**
```json
{
  "results": [
    {
      "id": 1,
      "date": "2025-08-09",
      "timeframe": "daily",
      "total_users": 1250,
      "active_users": 890,
      "new_users": 75,
      "returning_users": 815,
      "total_sessions": 2100,
      "total_pageviews": 18500,
      "average_session_duration": "00:12:30",
      "bounce_rate": "28.50",
      "users_with_requests": 180,
      "users_with_quotes": 145,
      "users_with_orders": 95
    }
  ]
}
```

### Get User Trends

**Endpoint:** `GET /user-behavior-analytics/user_trends/`

**Query Parameters:**
- `timeframe` (string): Time period (daily, weekly, monthly)
- `days` (integer): Number of days to include (default: 30)

**Example Request:**
```bash
curl -X GET "https://your-domain.com/analytics/api/v1/user-behavior-analytics/user_trends/?timeframe=daily&days=7" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 4. Search Analytics API

### List Search Analytics

**Endpoint:** `GET /search-analytics/`

**Example Request:**
```bash
curl -X GET "https://your-domain.com/analytics/api/v1/search-analytics/?ordering=-search_count" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Example Response:**
```json
{
  "results": [
    {
      "id": 1,
      "query": "gaming laptop",
      "query_hash": "5d41402abc4b2a76b9719d911017c592",
      "date": "2025-08-09",
      "search_count": 150,
      "results_count": 45,
      "clicks": 68,
      "average_position_clicked": "2.30",
      "zero_results": false,
      "click_through_rate": "45.33"
    }
  ]
}
```

### Get Top Search Queries

**Endpoint:** `GET /search-analytics/top_queries/`

**Query Parameters:**
- `days` (integer): Number of days to include (default: 7)
- `limit` (integer): Number of results (default: 20)

**Example Request:**
```bash
curl -X GET "https://your-domain.com/analytics/api/v1/search-analytics/top_queries/?days=30&limit=10" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Get Zero Result Queries

**Endpoint:** `GET /search-analytics/zero_result_queries/`

**Example Request:**
```bash
curl -X GET "https://your-domain.com/analytics/api/v1/search-analytics/zero_result_queries/?days=7" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 5. Sales Analytics API

### List Sales Analytics

**Endpoint:** `GET /sales-analytics/`

**Example Response:**
```json
{
  "results": [
    {
      "id": 1,
      "date": "2025-08-09",
      "timeframe": "daily",
      "total_orders": 125,
      "total_revenue": "285000.00",
      "total_units_sold": 650,
      "average_order_value": "2280.00",
      "average_units_per_order": "5.20",
      "total_quotes": 380,
      "accepted_quotes": 140,
      "quote_acceptance_rate": "36.84",
      "top_category": 5,
      "top_category_details": {
        "name": "Consumer Electronics"
      }
    }
  ]
}
```

### Get Revenue Trends

**Endpoint:** `GET /sales-analytics/revenue_trends/`

**Query Parameters:**
- `timeframe` (string): Time period (daily, weekly, monthly)
- `days` (integer): Number of days to include (default: 30)

**Example Request:**
```bash
curl -X GET "https://your-domain.com/analytics/api/v1/sales-analytics/revenue_trends/?timeframe=daily&days=14" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 6. Inventory Analytics API

### List Inventory Analytics

**Endpoint:** `GET /inventory-analytics/`

**Example Response:**
```json
{
  "results": [
    {
      "id": 1,
      "date": "2025-08-09",
      "timeframe": "daily",
      "total_products": 8500,
      "total_inventory_value": "12500000.00",
      "total_units": 45000,
      "in_stock_products": 7800,
      "out_of_stock_products": 450,
      "low_stock_products": 250,
      "units_received": 850,
      "units_sold": 920,
      "units_adjusted": -15,
      "inventory_turnover": "9.25",
      "days_of_inventory": "39.46"
    }
  ]
}
```

### Get Inventory Trends

**Endpoint:** `GET /inventory-analytics/inventory_trends/`

---

## 7. Analytics Reports API

### List Analytics Reports

**Endpoint:** `GET /reports/`

**Example Response:**
```json
{
  "results": [
    {
      "id": 1,
      "name": "Monthly Performance Report",
      "report_type": "product_performance",
      "description": "Comprehensive monthly analysis",
      "start_date": "2025-08-01",
      "end_date": "2025-08-31",
      "date_range_days": 31,
      "generated_by": 1,
      "generated_by_username": "admin",
      "status": "completed",
      "file_format": "json",
      "created_at": "2025-08-09T10:00:00Z"
    }
  ]
}
```

### Create Analytics Report

**Endpoint:** `POST /reports/`

**Example Request:**
```bash
curl -X POST "https://your-domain.com/analytics/api/v1/reports/" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Weekly Sales Report",
    "report_type": "sales_summary",
    "description": "Weekly sales performance analysis",
    "start_date": "2025-08-02",
    "end_date": "2025-08-09",
    "file_format": "csv"
  }'
```

### Generate Report

**Endpoint:** `POST /reports/{id}/generate/`

**Example Request:**
```bash
curl -X POST "https://your-domain.com/analytics/api/v1/reports/1/generate/" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Example Response:**
```json
{
  "id": 1,
  "name": "Weekly Sales Report",
  "status": "completed",
  "report_data": {
    "generated_at": "2025-08-09T15:30:00Z",
    "summary": "Report generated successfully",
    "data": []
  }
}
```

---

## 8. Analytics Dashboard API

### Get Dashboard Overview

**Endpoint:** `GET /dashboard/overview/`

**Query Parameters:**
- `timeframe` (string): Time period (daily, weekly, monthly)

**Example Request:**
```bash
curl -X GET "https://your-domain.com/analytics/api/v1/dashboard/overview/?timeframe=weekly" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Example Response:**
```json
{
  "timeframe": "weekly",
  "date_range": {
    "start": "2025-08-02",
    "end": "2025-08-09"
  },
  "summary": {
    "total_requests": 285,
    "active_requests": 235,
    "categories_with_requests": 12,
    "total_views": 12500,
    "total_quotes": 850,
    "avg_interest_score": 76.25,
    "total_revenue": 1250000.00,
    "avg_rating": 4.35
  }
}
```

### Get Dashboard Trends

**Endpoint:** `GET /dashboard/trends/`

**Query Parameters:**
- `days` (integer): Number of days to include (default: 30)

**Example Request:**
```bash
curl -X GET "https://your-domain.com/analytics/api/v1/dashboard/trends/?days=14" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Example Response:**
```json
{
  "date_range": {
    "start": "2025-07-26",
    "end": "2025-08-09"
  },
  "daily_requests": [
    {"day": "2025-08-08", "count": 25},
    {"day": "2025-08-09", "count": 32}
  ],
  "daily_analytics": [
    {"date": "2025-08-08", "total_views": 850, "total_quotes": 45},
    {"date": "2025-08-09", "total_views": 920, "total_quotes": 52}
  ]
}
```

---

## 9. Product Request Integration APIs

These endpoints are part of the product requests API but update analytics data.

### Track Click

**Endpoint:** `POST /product-requests/api/v1/requests/{id}/track_click/`

**Example Request:**
```bash
curl -X POST "https://your-domain.com/analytics/api/v1/requests/123/track_click/" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "source": "search"
  }'
```

**Example Response:**
```json
{
  "message": "Click tracked successfully",
  "request_id": "3de28ba4-95b6-4047-ab90-92eff49e3978",
  "source": "search"
}
```

### Track Search Appearance

**Endpoint:** `POST /product-requests/api/v1/requests/{id}/track_search_appearance/`

**Example Request:**
```bash
curl -X POST "https://your-domain.com/analytics/api/v1/requests/123/track_search_appearance/" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "gaming laptop dell",
    "position": 3
  }'
```

**Example Response:**
```json
{
  "message": "Search appearance tracked successfully",
  "request_id": "3de28ba4-95b6-4047-ab90-92eff49e3978",
  "query": "gaming laptop dell",
  "position": 3
}
```

---

## Error Responses

### Authentication Error

**Status Code:** 401 Unauthorized

```json
{
  "error": {
    "code": "authentication_failed",
    "message": "Authentication credentials were not provided or are invalid"
  }
}
```

### Validation Error

**Status Code:** 400 Bad Request

```json
{
  "error": {
    "code": "validation_error",
    "message": "Invalid input data",
    "details": {
      "timeframe": ["This field is required."],
      "date": ["Date has wrong format. Use YYYY-MM-DD."]
    }
  }
}
```

### Not Found Error

**Status Code:** 404 Not Found

```json
{
  "error": {
    "code": "not_found",
    "message": "The requested resource was not found."
  }
}
```

### Permission Error

**Status Code:** 403 Forbidden

```json
{
  "error": {
    "code": "permission_denied",
    "message": "You do not have permission to perform this action."
  }
}
```

---

## Testing Commands

### Run Python Tests

```bash
# Run all analytics tests
python manage.py test analytics.tests

# Run specific test class
python manage.py test analytics.tests.test_analytics_integration.AnalyticsAPITestCase

# Run with verbose output
python manage.py test analytics.tests --verbosity=2
```

### API Testing with Python requests

```python
import requests
import json

# Set up authentication
headers = {
    'Authorization': 'Bearer YOUR_TOKEN',
    'Content-Type': 'application/json'
}

base_url = 'https://your-domain.com/analytics/api/v1/'

# Test dashboard overview
response = requests.get(f"{base_url}dashboard/overview/", 
                       headers=headers, 
                       params={'timeframe': 'weekly'})
print(f"Status: {response.status_code}")
print(f"Data: {response.json()}")

# Test creating a report
report_data = {
    'name': 'Test Report',
    'report_type': 'product_performance',
    'start_date': '2025-08-01',
    'end_date': '2025-08-09',
    'file_format': 'json'
}

response = requests.post(f"{base_url}reports/", 
                        headers=headers, 
                        data=json.dumps(report_data))
print(f"Status: {response.status_code}")
print(f"Data: {response.json()}")
```

### Load Testing Example

```bash
# Install apache bench for load testing
# Test analytics dashboard endpoint
ab -n 100 -c 10 -H "Authorization: Bearer YOUR_TOKEN" "https://your-domain.com/analytics/api/v1/dashboard/overview/"
```

---

## Performance Considerations

1. **Pagination**: All list endpoints use pagination. Large datasets will be paginated with `page` and `page_size` parameters.

2. **Caching**: Consider implementing Redis caching for frequently accessed dashboard data.

3. **Database Indexing**: Analytics models include appropriate database indexes for performance.

4. **Rate Limiting**: Implement rate limiting to prevent abuse of analytics endpoints.

5. **Async Processing**: Report generation should be handled asynchronously for large datasets.

---

## Monitoring and Logging

1. Monitor API response times, especially for dashboard endpoints
2. Log analytics data updates and any errors during tracking
3. Set up alerts for failed report generations
4. Track API usage patterns to optimize performance

This documentation covers all analytics API endpoints with comprehensive examples and testing instructions.
