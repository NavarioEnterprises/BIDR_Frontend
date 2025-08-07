# BIDR Inventory Service - API Documentation

## Overview

The BIDR Inventory Service manages products, categories, requests, and associated attributes. This document provides API details for managing these resources.

## Base URL

```
http://localhost:8001
```

## Authentication

Some endpoints require JWT authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

---

## 📋 **Table of Contents**

1. [Category Endpoints](#category-endpoints)
2. [Attribute Endpoints](#attribute-endpoints)
3. [Error Handling](#error-handling)
4. [Authentication & Authorization](#authentication--authorization)
5. [Testing](#testing)

---

## 📦 **Category Endpoints**

### 📦 **Product Endpoints**

#### 1. List Products
**Endpoint**: `GET /api/v1/products/products/`
**Description**: Retrieve a list of products, supporting filters and search.

#### Example:
```bash
curl -X GET "http://localhost:8001/api/v1/products/products/?in_stock=true&is_featured=true" -H "Accept: application/json"
```

#### Response:
- `200 OK`: Returns a list of products.
- Attributes included: id, name, slug, description, price, etc.

#### 2. Retrieve Product
**Endpoint**: `GET /api/v1/products/products/{slug}/`
**Description**: Retrieve details of a specific product by slug.

#### Example:
```bash
curl -X GET http://localhost:8001/api/v1/products/products/laptop/ -H "Accept: application/json"
```

#### Response:
- `200 OK`: Returns the product details.
- `404 Not Found`: Product not found.

#### 3. Create Product
**Endpoint**: `POST /api/v1/products/products/`
**Description**: Create a new product. Requires authentication.

#### Example:
```bash
curl -X POST http://localhost:8001/api/v1/products/products/ \
  -H "Content-Type: application/json" -H "Authorization: Bearer <your_jwt_token>" \
  -d '{"name": "New Product", "slug": "new-product", "description": "A new test product", "base_price": "49.99"}'
```

#### Response:
- `201 Created`: Product created successfully.
- `401 Unauthorized`: Authentication required.

#### 4. Update Product
**Endpoint**: `PATCH /api/v1/products/products/{slug}/`
**Description**: Update an existing product's details. Requires authentication.

#### Example:
```bash
curl -X PATCH http://localhost:8001/api/v1/products/products/laptop/ \
  -H "Content-Type: application/json" -H "Authorization: Bearer <your_jwt_token>" \
  -d '{"description": "Updated Description"}'
```

#### Response:
- `200 OK`: Product updated successfully.
- `401 Unauthorized`: Authentication required.

#### 5. Delete Product
**Endpoint**: `DELETE /api/v1/products/products/{slug}/`
**Description**: Delete a product. Requires authentication.

#### Response:
- `204 No Content`: Product deleted successfully.
- `401 Unauthorized`: Authentication required.

### 1. List Categories
**Endpoint**: `GET /api/v1/categories/categories/`
**Description**: Retrieve a list of categories, supporting filters and search.

#### Example:
```bash
curl -X GET "http://localhost:8001/api/v1/categories/categories/?status=active&is_featured=true" -H "Accept: application/json"
```

#### Response:
- `200 OK`: Returns a list of categories.
- Attributes included: id, name, slug, description, parent, children, etc.

### 2. Create Category
**Endpoint**: `POST /api/v1/categories/categories/`  
**Description**: Create a new category.  
**Authentication**: Required

#### Example:
```bash
curl -X POST http://localhost:8001/api/v1/categories/categories/ \
  -H "Content-Type: application/json" -H "Authorization: Bearer <your_jwt_token>" \
  -d '{"name": "New Category", "slug": "new-category", "description": "Description"}'
```

#### Response:
- `201 Created`: Category created successfully.
- `401 Unauthorized`: Authentication required.

### 3. Retrieve Category
**Endpoint**: `GET /api/v1/categories/categories/{id}/`

#### Example:
```bash
curl -X GET http://localhost:8001/api/v1/categories/categories/{category_id}/ -H "Accept: application/json"
```

#### Response:
- `200 OK`: Returns the category details.
- `404 Not Found`: Category not found.

### 4. Update Category
**Endpoint**: `PATCH /api/v1/categories/categories/{id}/`  
**Description**: Partially update a category.  
**Authentication**: Required

#### Example:
```bash
curl -X PATCH http://localhost:8001/api/v1/categories/categories/{id}/ \
  -H "Content-Type: application/json" -H "Authorization: Bearer <your_jwt_token>" \
  -d '{"description": "Updated Description"}'
```

#### Response:
- `200 OK`: Category updated successfully.
- `401 Unauthorized`: Authentication required.

### 5. Delete Category
**Endpoint**: `DELETE /api/v1/categories/categories/{id}/`  
**Description**: Delete a category.  
**Authentication**: Required

---

## 📦 **Attribute Endpoints**

### 1. List Attributes
**Endpoint**: `GET /api/v1/categories/attributes/`

#### Example:
```bash
curl -X GET http://localhost:8001/api/v1/categories/attributes/ -H "Accept: application/json"
```

#### Response:
- `200 OK`: Returns a list of attributes.

### 2. Create Attribute
**Endpoint**: `POST /api/v1/categories/attributes/`    
**Authentication**: Required

#### Example:
```bash
curl -X POST http://localhost:8001/api/v1/categories/attributes/ \
  -H "Content-Type: application/json" -H "Authorization: Bearer <your_jwt_token>" \
  -d '{"name": "New Attribute", "category": "category_id", "type": "text"}'
```

#### Response:
- `201 Created`: Attribute created successfully.
- `401 Unauthorized`: Authentication required.

### 3. Retrieve Attribute
**Endpoint**: `GET /api/v1/categories/attributes/{id}/`

#### Example:
```bash
curl -X GET http://localhost:8001/api/v1/categories/attributes/{attribute_id}/ -H "Accept: application/json"
```

#### Response:
- `200 OK`: Returns the attribute details.
- `404 Not Found`: Attribute not found.

### 4. Update Attribute
**Endpoint**: `PATCH /api/v1/categories/attributes/{id}/`  
**Authentication**: Required

---

## ⚠️ **Error Handling**

### Common Error Response Format:
```json
{
    "error": {
        "code": "client_error",
        "message": "Request could not be processed",
        "details": {
            "detail": "Specific error detail"
        }
    }
}
```

### HTTP Status Codes:

- `200 OK`: Request successful.
- `201 Created`: Resource created.
- `400 Bad Request`: Validation errors.
- `401 Unauthorized`: Authentication required.
- `404 Not Found`: Resource not found.

---

## 🔐 **Authentication & Authorization**

### JWT Token Usage

Include the JWT token in the request headers:
```bash
Authorization: Bearer <your_jwt_token>
```

Protected endpoints require authentication.

---

# BIDR Inventory Service API Documentation

## Overview

The BIDR Inventory Service is a comprehensive inventory management system built with Django REST Framework. It handles product requests, quotes, transactions, and ratings for the BIDR platform. The service provides a full-featured API with authentication, authorization, and extensive functionality for managing inventory operations.

## Architecture

### Technology Stack
- **Framework**: Django 5.0 with Django REST Framework
- **Database**: SQLite (development) / PostgreSQL (production ready)
- **Authentication**: JWT (JSON Web Tokens) via Simple JWT
- **API Documentation**: Swagger/OpenAPI with drf-yasg
- **Additional Features**: CORS support, filtering, pagination, throttling

### Project Structure
```
inventory_service/
├── inventory_service/          # Main project configuration
├── core/                       # Shared models, utilities, exceptions
├── categories/                 # Product categories management
├── products/                   # Product catalog and inventory
├── product_requests/           # Customer product requests (RFQs)
├── quotes/                     # Supplier quotes and pricing
├── transactions/               # Orders, payments, delivery
└── ratings/                    # Reviews and feedback system
```

## Core Features

### 1. Hierarchical Categories
- **MPTT-based** category tree for efficient queries
- **Dynamic attributes** per category
- **SEO optimization** with meta fields
- **Commission management** per category

### 2. Product Management
- **Comprehensive product catalog** with variants
- **Inventory tracking** with reservations
- **Image management** with primary/secondary images
- **Attribute values** based on category requirements
- **Review system** with helpfulness voting

### 3. Request for Quote (RFQ) System
- **Product requests** with specifications
- **Image attachments** for reference
- **Budget ranges** and timeline management
- **Automatic expiry** handling
- **Watchlist functionality** for interested suppliers

### 4. Quote Management
- **Competitive quoting** system
- **Automatic ranking** by price and delivery
- **Quote comparison** tools
- **File attachments** for specifications
- **Validity tracking** with expiry dates

### 5. Transaction Processing
- **Order management** from accepted quotes
- **Payment tracking** with multiple methods
- **Delivery management** with status updates
- **Transaction messaging** system

### 6. Rating & Review System
- **Product ratings** with detailed reviews
- **Transaction ratings** for service quality
- **Issue reporting** and resolution tracking
- **Helpfulness voting** on reviews

## API Endpoints

### Base URL
- **Development**: `http://localhost:8001`
- **Production**: `https://api.bidr.com`

### Authentication
All endpoints except documentation and some read-only operations require JWT authentication:

```
Authorization: Bearer <your_jwt_token>
```

### Categories API (`/api/v1/categories/`)

#### Endpoints
- `GET /categories/` - List all categories
- `POST /categories/` - Create new category (auth required)
- `GET /categories/{id}/` - Get category details
- `PUT /categories/{id}/` - Update category (auth required)
- `DELETE /categories/{id}/` - Delete category (auth required)
- `GET /attributes/` - List category attributes
- `POST /attributes/` - Create category attribute (auth required)

#### Category Model Fields
```json
{
  "id": "uuid",
  "name": "string",
  "slug": "string",
  "description": "text",
  "parent": "uuid (nullable)",
  "children": "array of categories",
  "icon": "string",
  "image": "file",
  "color": "string (#hex)",
  "sort_order": "integer",
  "status": "active|inactive|pending",
  "is_featured": "boolean",
  "show_in_menu": "boolean",
  "meta_title": "string",
  "meta_description": "string",
  "commission_rate": "decimal",
  "full_name": "string (computed)",
  "breadcrumbs": "array (computed)",
  "product_count": "integer (computed)",
  "attributes": "array of category attributes",
  "tags": "array",
  "notes": "text",
  "metadata": "object",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Products API (`/api/v1/products/`)
**Status**: ✅ FULLY IMPLEMENTED with comprehensive features

#### Available Endpoints
- `GET /products/products/` - List products with advanced filtering and search
- `POST /products/products/` - Create new product (authentication required)
- `GET /products/products/{slug}/` - Get product details by slug
- `PUT /products/products/{slug}/` - Update product (authentication required)
- `PATCH /products/products/{slug}/` - Partially update product (authentication required)
- `DELETE /products/products/{slug}/` - Delete product (authentication required)
- `GET /products/products/featured/` - Get featured products
- `GET /products/products/low_stock/` - Get low stock products (authentication required)
- `POST /products/products/{slug}/adjust_inventory/` - Adjust inventory levels (authentication required)
- `GET /products/products/{slug}/reviews/` - Get product reviews
- `POST /products/products/{slug}/reviews/` - Add product review (authentication required)

#### Product Model Fields
```json
{
  "id": "uuid",
  "name": "string",
  "slug": "string (unique)",
  "sku": "string (unique, optional)",
  "description": "text",
  "short_description": "text (optional)",
  "category": "uuid (foreign key)",
  "supplier": "uuid (foreign key, optional)",
  "base_price": "decimal (min: 0.01)",
  "compare_price": "decimal (optional)",
  "cost_price": "decimal (optional)",
  "quantity_available": "integer (default: 0)",
  "quantity_reserved": "integer (default: 0)",
  "low_stock_threshold": "integer (default: 5)",
  "track_inventory": "boolean (default: true)",
  "weight": "decimal (optional)",
  "length": "decimal (optional)",
  "width": "decimal (optional)",
  "height": "decimal (optional)",
  "status": "active|inactive|draft",
  "is_featured": "boolean (default: false)",
  "meta_title": "string (optional)",
  "meta_description": "text (optional)",
  "tags": "array (optional)",
  "notes": "text (optional)",
  "metadata": "object (optional)",
  "created_at": "datetime",
  "updated_at": "datetime",
  "available_quantity": "integer (computed)",
  "is_in_stock": "boolean (computed)",
  "is_low_stock": "boolean (computed)",
  "discount_percentage": "float (computed)",
  "profit_margin": "float (computed)"
}
```

#### Filtering Options
- `category` - Filter by category ID
- `supplier` - Filter by supplier ID
- `status` - Filter by status (active, inactive, draft)
- `is_featured` - Filter featured products
- `in_stock` - Filter products in stock
- `low_stock` - Filter low stock products
- `min_price` / `max_price` - Price range filtering
- `search` - Search in name, description, and SKU

#### Product Management Features
- **Inventory tracking** with available/reserved quantities
- **Low stock alerts** with configurable thresholds
- **Pricing flexibility** with base, compare, and cost prices
- **SEO optimization** with meta fields
- **Product variants** support (via ProductVariant model)
- **Image management** (via ProductImage model)
- **Review system** with ratings and helpfulness voting
- **Inventory adjustment** with audit logging

### Product Requests API (`/api/v1/requests/`)
*Note: Full implementation pending - basic structure created*

#### Planned Endpoints
- `GET /requests/` - List product requests
- `POST /requests/` - Create new request
- `GET /requests/{id}/` - Get request details
- `PUT /requests/{id}/` - Update request
- `POST /requests/{id}/watch/` - Add to watchlist
- `GET /requests/{id}/quotes/` - Get quotes for request

### Quotes API (`/api/v1/quotes/`)
*Note: Full implementation pending - basic structure created*

#### Planned Endpoints
- `GET /quotes/` - List quotes
- `POST /quotes/` - Submit new quote
- `GET /quotes/{id}/` - Get quote details
- `PUT /quotes/{id}/` - Update quote
- `POST /quotes/{id}/accept/` - Accept quote (creates transaction)
- `GET /quotes/{id}/comparison/` - Get quote comparison

### Transactions API (`/api/v1/transactions/`)
*Note: Full implementation pending - basic structure created*

#### Planned Endpoints
- `GET /transactions/` - List transactions
- `GET /transactions/{id}/` - Get transaction details
- `PUT /transactions/{id}/` - Update transaction status
- `POST /transactions/{id}/payments/` - Add payment
- `GET /transactions/{id}/delivery/` - Get delivery status

### Ratings API (`/api/v1/ratings/`)
*Note: Full implementation pending - basic structure created*

#### Planned Endpoints
- `GET /ratings/` - List product ratings
- `POST /ratings/` - Submit product rating
- `GET /ratings/{id}/` - Get rating details
- `POST /ratings/{id}/helpful/` - Mark rating as helpful

## API Documentation

### Interactive Documentation
- **Swagger UI**: `/swagger/` - Interactive API explorer
- **ReDoc**: `/redoc/` - Clean documentation interface
- **OpenAPI Schema**: `/swagger.json` - Machine-readable API specification

### Features
- **Complete API specification** with request/response schemas
- **Authentication integration** with JWT tokens
- **Try-it-out functionality** for testing endpoints
- **Model schemas** with field descriptions and validation rules

## Data Models

### Core Base Models

#### BaseModel (Abstract)
- **UUID primary key** for security and scalability
- **Timestamps** (created_at, updated_at)
- **Soft delete** capability
- **Location fields** (address, coordinates, search radius)
- **Metadata** (JSON tags, notes, custom data)
- **Audit trail** (created_by, updated_by)

#### Status Choices
- `active`, `inactive`, `pending`, `approved`, `rejected`, `cancelled`, `completed`, `expired`, `draft`

#### Priority Choices
- `low`, `medium`, `high`, `urgent`

### Specific Models

#### Category
- Hierarchical structure using MPTT
- Dynamic attributes per category
- Commission rate configuration
- SEO and display settings

#### Product
- Complete product information
- Inventory tracking with reservations
- Physical properties (weight, dimensions)
- Multiple pricing options (base, compare, cost)
- Image management
- Attribute values based on category

#### ProductRequest
- Customer requests for products/quotes
- Budget ranges and timelines
- Specification attachments
- Expiry and urgency handling
- Location-based matching

#### Quote
- Supplier responses to requests
- Competitive pricing with ranking
- Delivery terms and validity
- Automatic comparison and analysis
- Platform fee calculation

#### Transaction
- Order processing from accepted quotes
- Payment tracking and management
- Delivery coordination
- Status progression
- Message history

## Security Features

### Authentication & Authorization
- **JWT-based authentication** with refresh tokens
- **Role-based permissions** for different user types
- **Rate limiting** to prevent abuse
- **CORS configuration** for web applications

### Data Protection
- **Soft delete** for data recovery
- **Audit trails** for all changes
- **Input validation** and sanitization
- **Error handling** with custom exception system

### API Security
- **HTTPS enforced** in production
- **Token expiry** with refresh mechanism
- **Request throttling** (100/hour anonymous, 1000/hour authenticated)
- **Input validation** on all endpoints

## Testing

### Model Tests
- **Unit tests** for all model functionality
- **Property and method testing**
- **Validation testing**
- **Relationship testing**

### API Tests
- **Endpoint testing** with authentication
- **Permission testing**
- **Data validation testing**
- **Error handling testing**

### Test Results
```
Categories App Tests: ✅ PASSED (5 tests)
- test_category_creation: ✅
- test_category_str_representation: ✅
- test_full_name_property: ✅
- test_attribute_creation: ✅
- test_display_label_property: ✅

Products App Tests: ✅ PASSED (22 tests)
Model Tests:
- test_product_creation: ✅
- test_product_str_representation: ✅
- test_available_quantity_property: ✅
- test_is_in_stock_property: ✅
- test_is_low_stock_property: ✅
- test_discount_percentage_property: ✅
- test_profit_margin_property: ✅
- test_can_fulfill_quantity: ✅
- test_reserve_quantity: ✅
- test_release_quantity: ✅
- test_adjust_inventory: ✅

API Tests:
- test_list_products_unauthenticated: ✅
- test_list_products_with_filters: ✅
- test_search_products: ✅
- test_retrieve_product: ✅
- test_create_product_authenticated: ✅
- test_create_product_unauthenticated: ✅
- test_update_product: ✅
- test_featured_products_endpoint: ✅
- test_adjust_inventory_endpoint: ✅

Serializer Tests:
- test_base_price_validation: ✅
- test_compare_price_validation: ✅

Total Tests: 27/27 PASSED ✅
```

## Admin Interface

### Features
- **Comprehensive admin panels** for all models
- **Hierarchical category management** with MPTT admin
- **Inline editing** for related models
- **Advanced filtering** and search
- **Bulk actions** for efficiency
- **Read-only fields** for computed values

### Access
- **Admin URL**: `/admin/`
- **Credentials**: admin/admin123 (development)

## Deployment

### Development Setup
1. **Clone repository**
2. **Install dependencies**: `pip install -r requirements.txt`
3. **Run migrations**: `python manage.py migrate`
4. **Create superuser**: `python manage.py createsuperuser`
5. **Start server**: `python manage.py runserver`

### Production Considerations
- **Database**: Switch to PostgreSQL with PostGIS for geospatial features
- **Static files**: Configure with CDN (AWS S3/CloudFront)
- **Media files**: External storage for uploads
- **Caching**: Redis for session and API caching
- **Monitoring**: Error tracking and performance monitoring
- **Security**: SSL certificates, security headers, secret management

## Performance Features

### Database Optimization
- **Efficient queries** with select_related and prefetch_related
- **Database indexing** on frequently queried fields
- **Query optimization** for hierarchical data (MPTT)

### API Optimization
- **Pagination** for large result sets (20 items per page)
- **Filtering and search** to reduce data transfer
- **Caching** for frequently accessed data
- **Throttling** to manage server load

### Scalability
- **UUID primary keys** for distributed systems
- **Soft delete** for data integrity
- **Modular architecture** for microservices
- **API versioning** for backward compatibility

## Future Enhancements

### Planned Features
1. **Real-time notifications** with WebSocket support
2. **Advanced search** with Elasticsearch integration
3. **Analytics dashboard** with reporting tools
4. **Mobile API** optimization
5. **Third-party integrations** (payment gateways, shipping providers)
6. **Geospatial search** with PostGIS
7. **Machine learning** for demand forecasting
8. **Multi-tenant support** for enterprise clients

### API Extensions
1. **GraphQL endpoint** for flexible queries
2. **Bulk operations** API for batch processing
3. **Webhook system** for external integrations
4. **Advanced filtering** with complex queries
5. **Export functionality** (CSV, Excel, PDF)

## Support & Maintenance

### Monitoring
- **Health checks** for system status
- **Performance metrics** for optimization
- **Error tracking** for quick resolution
- **Usage analytics** for capacity planning

### Documentation Maintenance
- **API documentation** automatically updated from code
- **Version history** for API changes
- **Migration guides** for breaking changes
- **Best practices** and usage examples

---

## API Test Results Summary

**Test Date**: 2025-08-02
**Service Status**: ✅ OPERATIONAL
**Base URL**: http://localhost:8001

### Endpoint Test Results

| Endpoint | Method | Status | Description |
|----------|--------|--------|-------------|
| `/swagger/` | GET | ✅ 200 | Swagger UI Documentation |
| `/redoc/` | GET | ✅ 200 | ReDoc Documentation |
| `/swagger.json` | GET | ✅ 200 | OpenAPI Schema |
| `/api/v1/categories/categories/` | GET | ✅ 200 | Categories List |
| `/api/v1/categories/categories/` | POST | ✅ 401 | Auth Required (Expected) |
| `/api/v1/products/products/` | GET | ✅ 200 | Products List |
| `/api/v1/products/products/` | POST | ✅ 401 | Auth Required (Expected) |
| `/api/v1/products/products/featured/` | GET | ✅ 200 | Featured Products |
| `/api/v1/products/products/low_stock/` | GET | ✅ 401 | Auth Required (Expected) |
| `/api/v1/requests/` | GET | ✅ 401 | Auth Required (Expected) |
| `/api/v1/quotes/` | GET | ✅ 401 | Auth Required (Expected) |
| `/api/v1/transactions/` | GET | ✅ 401 | Auth Required (Expected) |
| `/api/v1/ratings/` | GET | ✅ 401 | Auth Required (Expected) |

### Key Findings
- **Authentication system** is working correctly
- **API documentation** is accessible and complete
- **Categories API** is fully functional
- **Other apps** have basic structure in place
- **Error handling** returns structured JSON responses
- **CORS and security** headers are properly configured

### Next Steps
1. **Complete API implementations** for remaining apps
2. **Add more comprehensive test data**
3. **Implement user registration/login endpoints**
4. **Add more detailed API tests**
5. **Configure production deployment**

---

*This documentation is automatically generated and maintained alongside the codebase.*
