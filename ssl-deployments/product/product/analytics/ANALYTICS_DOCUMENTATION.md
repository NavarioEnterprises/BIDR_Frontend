# Analytics App Documentation

## Overview

The analytics app has been completely updated to work with the product requests system instead of the removed products app. It provides comprehensive analytics and reporting capabilities for:

- Product Request Analytics
- Category Analytics  
- User Behavior Analytics
- Search Analytics
- Sales Analytics
- Inventory Analytics
- Analytics Reports

## Models

### ProductRequestAnalytics

Tracks analytics data for individual product requests.

**Key Fields:**
- `request` - ForeignKey to ProductRequest
- `date` - Date for the analytics record
- `timeframe` - Period type (hourly, daily, weekly, monthly, quarterly, yearly)
- `views` - Number of views
- `unique_views` - Number of unique views
- `search_appearances` - Times request appeared in search results
- `search_clicks` - Times request was clicked from search results
- `quote_responses` - Number of quote responses received
- `messages_sent` - Number of messages sent to requestor
- `watchlist_additions` - Number of times added to watchlist
- `average_response_time` - Average response time for quotes
- `supplier_interest_score` - Score based on supplier engagement (0-100)

**Calculated Properties:**
- `click_through_rate` - CTR from search appearances
- `response_rate` - Response rate based on views to quotes

### CategoryAnalytics

Tracks analytics data for product categories.

**Key Fields:**
- `category` - ForeignKey to Category
- `date` - Date for the analytics record
- `timeframe` - Period type
- `total_requests` - Total number of product requests in category
- `active_requests` - Number of active product requests
- `new_requests` - New product requests added in this period
- `closed_requests` - Number of closed requests in this period
- `total_views` - Total views across category
- `total_quote_requests` - Total quote requests
- `total_quotes` - Total quotes submitted
- `total_orders` - Total orders
- `total_revenue` - Total revenue generated
- `average_price` - Average product price in category
- `average_rating` - Average product rating in category

### UserBehaviorAnalytics

Tracks user behavior patterns.

**Key Fields:**
- `date` - Date for the analytics record
- `timeframe` - Period type
- `total_users` - Total number of users
- `active_users` - Number of active users
- `new_users` - New users in this period
- `returning_users` - Returning users
- `total_sessions` - Total user sessions
- `total_pageviews` - Total page views
- `average_session_duration` - Average session length
- `bounce_rate` - Bounce rate percentage
- `users_with_requests` - Users who made at least one request
- `users_with_quotes` - Users who submitted at least one quote
- `users_with_orders` - Users who made at least one order

### SearchAnalytics

Tracks search queries and results.

**Key Fields:**
- `query` - The search query
- `query_hash` - Hash of the query for grouping
- `date` - Date for the analytics record
- `search_count` - Number of times this query was searched
- `results_count` - Number of results returned
- `clicks` - Number of clicks on results
- `average_position_clicked` - Average position of clicked results
- `zero_results` - Whether this query returned zero results

**Calculated Properties:**
- `click_through_rate` - Click-through rate for searches

### SalesAnalytics

Tracks sales performance.

**Key Fields:**
- `date` - Date for the analytics record
- `timeframe` - Period type
- `total_orders` - Total number of orders
- `total_revenue` - Total revenue generated
- `total_units_sold` - Total units sold
- `average_order_value` - Average order value
- `average_units_per_order` - Average units per order
- `total_quotes` - Total quotes submitted
- `accepted_quotes` - Number of accepted quotes
- `quote_acceptance_rate` - Quote acceptance rate percentage
- `top_category` - ForeignKey to top performing category

### InventoryAnalytics

Tracks inventory performance and movement.

**Key Fields:**
- `date` - Date for the analytics record
- `timeframe` - Period type
- `total_products` - Total number of products
- `total_inventory_value` - Total value of inventory
- `total_units` - Total number of units in stock
- `in_stock_products` - Number of products in stock
- `out_of_stock_products` - Number of products out of stock
- `low_stock_products` - Number of products with low stock
- `units_received` - Units added to inventory
- `units_sold` - Units sold from inventory
- `units_adjusted` - Units adjusted (positive or negative)
- `inventory_turnover` - Inventory turnover ratio
- `days_of_inventory` - Days of inventory remaining

### AnalyticsReport

Manages generated analytics reports.

**Key Fields:**
- `name` - Report name
- `report_type` - Type of report (product_performance, sales_summary, etc.)
- `description` - Report description
- `start_date` - Start date of report period
- `end_date` - End date of report period
- `generated_by` - ForeignKey to User who generated the report
- `status` - Report status (pending, completed, failed)
- `report_data` - JSON field containing report data
- `file_path` - Path to generated report file
- `file_format` - Format of the report (json, csv, pdf, excel)
- `parameters` - JSON field with generation parameters
- `generation_time` - Time taken to generate the report

## API Endpoints

### ProductRequestAnalytics API
- `GET /analytics/api/v1/product-request-analytics/` - List all analytics
- `POST /analytics/api/v1/product-request-analytics/` - Create new analytics
- `GET /analytics/api/v1/product-request-analytics/{id}/` - Get specific analytics
- `PUT /analytics/api/v1/product-request-analytics/{id}/` - Update analytics
- `DELETE /analytics/api/v1/product-request-analytics/{id}/` - Delete analytics

**Special Endpoints:**
- `GET /analytics/api/v1/product-request-analytics/top_performing_requests/` - Get top performing requests
- `GET /analytics/api/v1/product-request-analytics/category_performance/` - Get category performance summary

### CategoryAnalytics API
- `GET /analytics/api/v1/category-analytics/` - List all category analytics
- `GET /analytics/api/v1/category-analytics/top_categories/` - Get top performing categories

### UserBehaviorAnalytics API
- `GET /analytics/api/v1/user-behavior-analytics/` - List user behavior analytics
- `GET /analytics/api/v1/user-behavior-analytics/user_trends/` - Get user behavior trends

### SearchAnalytics API
- `GET /analytics/api/v1/search-analytics/` - List search analytics
- `GET /analytics/api/v1/search-analytics/top_queries/` - Get top search queries
- `GET /analytics/api/v1/search-analytics/zero_result_queries/` - Get queries with zero results

### SalesAnalytics API
- `GET /analytics/api/v1/sales-analytics/` - List sales analytics
- `GET /analytics/api/v1/sales-analytics/revenue_trends/` - Get revenue trends

### InventoryAnalytics API
- `GET /analytics/api/v1/inventory-analytics/` - List inventory analytics
- `GET /analytics/api/v1/inventory-analytics/inventory_trends/` - Get inventory trends

### AnalyticsReport API
- `GET /analytics/api/v1/reports/` - List all reports
- `POST /analytics/api/v1/reports/` - Create new report
- `POST /analytics/api/v1/reports/{id}/generate/` - Generate report data

### Dashboard API
- `GET /analytics/api/v1/dashboard/overview/` - Get analytics overview dashboard
- `GET /analytics/api/v1/dashboard/trends/` - Get trending data over time

## Admin Interface

All analytics models are registered with comprehensive admin interfaces including:

- List displays with key metrics
- Filtering by date, timeframe, and related objects
- Search functionality
- Readonly fields for calculated metrics
- Date hierarchy navigation
- Organized fieldsets for better UX
- Custom display methods for formatted values

## Management Commands

### generate_sample_analytics

Generates sample analytics data for testing and development.

**Usage:**
```bash
python manage.py generate_sample_analytics --days=30 --clear
```

**Options:**
- `--days` - Number of days of data to generate (default: 30)
- `--clear` - Clear existing analytics data first

## Query Examples

### Get ProductRequest Analytics Summary
```python
from django.db.models import Sum, Avg, Count
from analytics.models import ProductRequestAnalytics

summary = ProductRequestAnalytics.objects.aggregate(
    total_views=Sum('views'),
    total_quotes=Sum('quote_responses'),
    avg_interest_score=Avg('supplier_interest_score'),
    count=Count('id')
)
```

### Get Category Performance
```python
from analytics.models import CategoryAnalytics

category_performance = CategoryAnalytics.objects.values(
    'category__name'
).annotate(
    total_revenue=Sum('total_revenue'),
    total_requests=Sum('total_requests')
).order_by('-total_revenue')
```

### Get Search Query Statistics
```python
from analytics.models import SearchAnalytics

top_queries = SearchAnalytics.objects.filter(
    zero_results=False
).order_by('-search_count')[:20]
```

## Integration with Product Requests

The analytics app is fully integrated with the product requests system:

1. **ProductRequestAnalytics** tracks metrics for individual product requests
2. **CategoryAnalytics** aggregates data by product request categories
3. All analytics models reference the updated category and product request models
4. API endpoints support filtering by product request attributes

## Authentication

All API endpoints require authentication. Users must be authenticated to access analytics data.

## Testing

The analytics functionality can be tested using the included test script:

```bash
python analytics/test_analytics_simple.py
```

This script tests:
- Model functionality and string representations
- Calculated properties (CTR, response rates, etc.)
- Analytics aggregations and summaries
- Database queries and relationships

## Data Migration

The analytics app includes migration files that:
1. Update CategoryAnalytics to work with product requests instead of products
2. Add the new ProductRequestAnalytics model
3. Maintain existing analytics data where possible

## Performance Considerations

- All models include appropriate database indexes
- Admin queries use `select_related()` for efficiency
- Analytics data should be aggregated periodically rather than calculated in real-time
- Consider using database views or materialized views for complex analytics queries

## Future Enhancements

Potential areas for expansion:
1. Real-time analytics dashboard
2. Advanced reporting with charts and graphs
3. Email/SMS alerts for significant metric changes
4. Machine learning insights and predictions
5. Export functionality for analytics data
6. Scheduled report generation and distribution
7. Custom analytics metrics and KPIs
8. Integration with external analytics platforms
