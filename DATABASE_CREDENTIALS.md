# BIDR PostgreSQL Database Credentials

## PostgreSQL Connection Details
- **Host:** postgres-service
- **Port:** 5432
- **Master User:** bidruser
- **Master Password:** fPk4b45tCZezxsrbEwtkUPjaZf27+V/w0Kt/AET14iA=

## Service-Specific Database Configurations

### 1. Authentication Service
- **Database Name:** bidr_auth
- **Secret Name:** auth-db-secret
- **Admin URL:** http://74.179.193.18/auth/admin/

### 2. Product Management Service
- **Database Name:** bidr_products  
- **Secret Name:** product-db-secret
- **Admin URL:** http://74.179.193.18/products/admin/

### 3. Reviews & Ratings Service
- **Database Name:** bidr_reviews
- **Secret Name:** reviews-db-secret
- **Admin URL:** http://74.179.193.18/reviews/admin/

### 4. Chat Service
- **Database Name:** bidr_chat
- **Secret Name:** chat-db-secret
- **Admin URL:** http://74.179.193.18/chat/admin/

### 5. Notifications Service
- **Database Name:** bidr_notifications
- **Secret Name:** notifications-db-secret
- **Admin URL:** http://74.179.193.18/notifications/admin/

### 6. Payment Service
- **Database Name:** bidr_payments
- **Secret Name:** payment-db-secret
- **Admin URL:** http://74.179.193.18/payments/admin/

### 7. Resolution Service
- **Database Name:** bidr_resolution
- **Secret Name:** resolution-db-secret
- **Admin URL:** http://74.179.193.18/resolution/admin/

## Kubernetes Secret Structure
Each service has its own secret containing:
```yaml
DB_NAME: <service_specific_database>
DB_USER: bidruser
DB_PASSWORD: fPk4b45tCZezxsrbEwtkUPjaZf27+V/w0Kt/AET14iA=
DB_HOST: postgres-service
DB_PORT: 5432
```

## Django Settings Configuration
All services have been updated to use PostgreSQL when deployed in Kubernetes:
```python
if os.path.exists('/etc/secrets/db'):
    # Read database credentials from Kubernetes secrets
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': os.environ.get('DB_NAME'),
            'USER': os.environ.get('DB_USER'),
            'PASSWORD': os.environ.get('DB_PASSWORD'),
            'HOST': os.environ.get('DB_HOST'),
            'PORT': os.environ.get('DB_PORT'),
        }
    }
```

## Database Migration Commands
To run migrations for each service:
```bash
# Auth Service
kubectl exec -it <auth-pod> -n bidr -- python manage.py migrate

# Product Management Service  
kubectl exec -it <product-pod> -n bidr -- sh -c "cd /app/product_management_service && python manage.py migrate"

# Reviews Service
kubectl exec -it <reviews-pod> -n bidr -- sh -c "cd /app/reviews_and_ratings && python manage.py migrate"

# Chat Service
kubectl exec -it <chat-pod> -n bidr -- sh -c "cd /app/chat_service && python manage.py migrate"

# Other services follow similar patterns
```

## Notes
- All services share the same PostgreSQL user but have separate databases
- Database secrets are mounted as environment variables
- Services automatically detect Kubernetes environment and switch to PostgreSQL
- In local development, services default to SQLite