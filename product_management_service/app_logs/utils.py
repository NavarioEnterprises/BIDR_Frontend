"""
Utility functions for application logging.

This module provides convenient functions for logging application events
manually from views, serializers, and other parts of the application.
"""

import logging
from django.contrib.auth.models import User, AnonymousUser
from django.utils import timezone
from .models import ApplicationLog, ProductRequestLog, CategoryLog, LogLevel, EventType

logger = logging.getLogger(__name__)


def log_user_action(user, action, message, category='user_action', **kwargs):
    """
    Log a user action to the application logs.
    
    Args:
        user: User instance or None for anonymous
        action: Action performed (e.g., 'login', 'create_request', 'update_profile')
        message: Human-readable log message
        category: Log category (default: 'user_action')
        **kwargs: Additional context data
    
    Returns:
        ApplicationLog instance or None if logging failed
    """
    try:
        context_data = {
            'action': action,
            'timestamp': timezone.now().isoformat(),
        }
        context_data.update(kwargs)
        
        # Add user info if available
        if user and not isinstance(user, AnonymousUser):
            context_data['user_id'] = user.id
            context_data['username'] = user.username
        
        return ApplicationLog.objects.create(
            level=LogLevel.INFO,
            event_type=EventType.USER_ACTION,
            message=message,
            category=category,
            user=user if user and not isinstance(user, AnonymousUser) else None,
            context_data=context_data
        )
        
    except Exception as e:
        logger.error(f"Failed to log user action: {e}")
        return None


def log_business_event(event_type, message, category, level=LogLevel.INFO, user=None, **kwargs):
    """
    Log a business logic event.
    
    Args:
        event_type: Type of event (EventType enum)
        message: Human-readable log message
        category: Log category
        level: Log level (default: INFO)
        user: User instance or None
        **kwargs: Additional context data
    
    Returns:
        ApplicationLog instance or None if logging failed
    """
    try:
        context_data = {
            'timestamp': timezone.now().isoformat(),
        }
        context_data.update(kwargs)
        
        return ApplicationLog.objects.create(
            level=level,
            event_type=event_type,
            message=message,
            category=category,
            user=user if user and not isinstance(user, AnonymousUser) else None,
            context_data=context_data
        )
        
    except Exception as e:
        logger.error(f"Failed to log business event: {e}")
        return None


def log_product_request_event(product_request_id, action, user=None, details=None, **kwargs):
    """
    Log a product request related event.
    
    Args:
        product_request_id: UUID or string ID of the product request
        action: Action performed (e.g., 'created', 'updated', 'viewed')
        user: User who performed the action
        details: Additional action details
        **kwargs: Additional context data
    
    Returns:
        ProductRequestLog instance or None if logging failed
    """
    try:
        context_data = kwargs.copy() if kwargs else {}
        
        if details:
            context_data['details'] = details
            
        context_data['timestamp'] = timezone.now().isoformat()
        
        # Get product request title if possible
        title = None
        try:
            from product_requests.models import ProductRequest
            pr = ProductRequest.objects.get(id=product_request_id)
            title = pr.title
            context_data['category'] = pr.category.name if pr.category else None
        except Exception:
            pass
        
        return ProductRequestLog.objects.create(
            product_request_id=str(product_request_id),
            action=action,
            user=user if user and not isinstance(user, AnonymousUser) else None,
            ip_address=kwargs.get('ip_address', ''),
            user_agent=kwargs.get('user_agent', ''),
            title=title,
            action_details=context_data
        )
        
    except Exception as e:
        logger.error(f"Failed to log product request event: {e}")
        return None


def log_category_event(category_id, event, user=None, event_data=None, **kwargs):
    """
    Log a category related event.
    
    Args:
        category_id: ID of the category
        event: Event type (e.g., 'accessed', 'modified', 'searched')
        user: User who triggered the event
        event_data: Additional event data
        **kwargs: Additional context data
    
    Returns:
        CategoryLog instance or None if logging failed
    """
    try:
        # Get category name if possible
        category_name = f"Category {category_id}"
        try:
            from categories.models import Category
            category = Category.objects.get(id=category_id)
            category_name = category.name
        except Exception:
            pass
        
        context_data = kwargs.copy() if kwargs else {}
        context_data['timestamp'] = timezone.now().isoformat()
        
        if event_data:
            context_data.update(event_data)
        
        return CategoryLog.objects.create(
            category_id=category_id,
            category_name=category_name,
            event=event,
            user=user if user and not isinstance(user, AnonymousUser) else None,
            event_data=context_data,
            request_count=kwargs.get('request_count', 1)
        )
        
    except Exception as e:
        logger.error(f"Failed to log category event: {e}")
        return None


def log_authentication_event(user, event_type, success=True, ip_address='', user_agent='', **kwargs):
    """
    Log authentication related events.
    
    Args:
        user: User instance
        event_type: Type of auth event ('login', 'logout', 'token_refresh', etc.)
        success: Whether the event was successful
        ip_address: Client IP address
        user_agent: Client user agent
        **kwargs: Additional context data
    
    Returns:
        ApplicationLog instance or None if logging failed
    """
    try:
        level = LogLevel.INFO if success else LogLevel.WARNING
        message = f"Authentication {event_type} {'successful' if success else 'failed'}"
        
        if user and not isinstance(user, AnonymousUser):
            message += f" for user {user.username}"
        
        context_data = {
            'event_type': event_type,
            'success': success,
            'ip_address': ip_address,
            'user_agent': user_agent,
            'timestamp': timezone.now().isoformat(),
        }
        context_data.update(kwargs)
        
        return ApplicationLog.objects.create(
            level=level,
            event_type=EventType.AUTHENTICATION,
            message=message,
            category='authentication',
            subcategory=event_type,
            user=user if user and not isinstance(user, AnonymousUser) else None,
            ip_address=ip_address,
            context_data=context_data
        )
        
    except Exception as e:
        logger.error(f"Failed to log authentication event: {e}")
        return None


def log_system_event(event_type, message, level=LogLevel.INFO, **kwargs):
    """
    Log system-level events.
    
    Args:
        event_type: Type of system event
        message: Human-readable log message
        level: Log level (default: INFO)
        **kwargs: Additional context data
    
    Returns:
        ApplicationLog instance or None if logging failed
    """
    try:
        context_data = {
            'timestamp': timezone.now().isoformat(),
        }
        context_data.update(kwargs)
        
        return ApplicationLog.objects.create(
            level=level,
            event_type=EventType.SYSTEM_EVENT,
            message=message,
            category='system',
            context_data=context_data
        )
        
    except Exception as e:
        logger.error(f"Failed to log system event: {e}")
        return None


def log_data_change(model_name, object_id, change_type, user=None, old_values=None, new_values=None, **kwargs):
    """
    Log data changes for audit purposes.
    
    Args:
        model_name: Name of the model that changed
        object_id: ID of the object that changed
        change_type: Type of change ('create', 'update', 'delete')
        user: User who made the change
        old_values: Previous values (for updates)
        new_values: New values (for creates/updates)
        **kwargs: Additional context data
    
    Returns:
        ApplicationLog instance or None if logging failed
    """
    try:
        message = f"{change_type.title()} {model_name} {object_id}"
        
        context_data = {
            'model': model_name,
            'object_id': str(object_id),
            'change_type': change_type,
            'timestamp': timezone.now().isoformat(),
        }
        
        if old_values:
            context_data['old_values'] = old_values
        if new_values:
            context_data['new_values'] = new_values
            
        context_data.update(kwargs)
        
        return ApplicationLog.objects.create(
            level=LogLevel.INFO,
            event_type=EventType.DATA_CHANGE,
            message=message,
            category='data_change',
            subcategory=model_name.lower(),
            user=user if user and not isinstance(user, AnonymousUser) else None,
            context_data=context_data
        )
        
    except Exception as e:
        logger.error(f"Failed to log data change: {e}")
        return None


def get_user_activity_summary(user, days=30):
    """
    Get a summary of user activity from logs.
    
    Args:
        user: User instance
        days: Number of days to look back (default: 30)
    
    Returns:
        Dictionary with activity summary
    """
    try:
        from datetime import timedelta
        from django.db.models import Count
        
        since_date = timezone.now() - timedelta(days=days)
        
        # Get activity from ApplicationLog
        app_logs = ApplicationLog.objects.filter(
            user=user,
            timestamp__gte=since_date
        )
        
        # Get activity from ProductRequestLog
        pr_logs = ProductRequestLog.objects.filter(
            user=user,
            timestamp__gte=since_date
        )
        
        summary = {
            'total_actions': app_logs.count() + pr_logs.count(),
            'app_log_actions': app_logs.count(),
            'product_request_actions': pr_logs.count(),
            'categories_accessed': app_logs.filter(category='categories').count(),
            'analytics_queries': app_logs.filter(category='analytics').count(),
            'auth_events': app_logs.filter(category='authentication').count(),
            'most_common_actions': list(
                pr_logs.values('action').annotate(
                    count=Count('action')
                ).order_by('-count')[:5]
            ),
            'period_days': days,
            'start_date': since_date.isoformat(),
            'end_date': timezone.now().isoformat(),
        }
        
        return summary
        
    except Exception as e:
        logger.error(f"Failed to get user activity summary: {e}")
        return {
            'error': str(e),
            'total_actions': 0,
        }


class ApplicationLogger:
    """
    Context manager and utility class for application logging.
    
    Usage:
        with ApplicationLogger(user=request.user, category='product_requests') as log:
            # Do some work
            log.info("Created product request", request_id=request.id)
            log.warning("Invalid data detected", data=invalid_data)
    """
    
    def __init__(self, user=None, category='general', ip_address='', user_agent=''):
        self.user = user
        self.category = category
        self.ip_address = ip_address
        self.user_agent = user_agent
        self.logs_created = []
    
    def __enter__(self):
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type:
            # Log exception if one occurred
            self.error(
                f"Exception in {self.category}: {exc_type.__name__}",
                exception=str(exc_val)
            )
    
    def _create_log(self, level, event_type, message, **kwargs):
        """Create an application log entry."""
        try:
            context_data = {
                'ip_address': self.ip_address,
                'user_agent': self.user_agent,
                'timestamp': timezone.now().isoformat(),
            }
            context_data.update(kwargs)
            
            log_entry = ApplicationLog.objects.create(
                level=level,
                event_type=event_type,
                message=message,
                category=self.category,
                user=self.user if self.user and not isinstance(self.user, AnonymousUser) else None,
                ip_address=self.ip_address,
                context_data=context_data
            )
            
            self.logs_created.append(log_entry)
            return log_entry
            
        except Exception as e:
            logger.error(f"Failed to create application log: {e}")
            return None
    
    def info(self, message, **kwargs):
        """Log an info level message."""
        return self._create_log(LogLevel.INFO, EventType.BUSINESS_LOGIC, message, **kwargs)
    
    def warning(self, message, **kwargs):
        """Log a warning level message."""
        return self._create_log(LogLevel.WARNING, EventType.BUSINESS_LOGIC, message, **kwargs)
    
    def error(self, message, **kwargs):
        """Log an error level message."""
        return self._create_log(LogLevel.ERROR, EventType.ERROR_EVENT, message, **kwargs)
    
    def debug(self, message, **kwargs):
        """Log a debug level message."""
        return self._create_log(LogLevel.DEBUG, EventType.SYSTEM_EVENT, message, **kwargs)
    
    def user_action(self, action, message, **kwargs):
        """Log a user action."""
        kwargs['action'] = action
        return self._create_log(LogLevel.INFO, EventType.USER_ACTION, message, **kwargs)
    
    def data_change(self, change_type, model_name, object_id, **kwargs):
        """Log a data change."""
        message = f"{change_type.title()} {model_name} {object_id}"
        kwargs.update({
            'change_type': change_type,
            'model': model_name,
            'object_id': str(object_id)
        })
        return self._create_log(LogLevel.INFO, EventType.DATA_CHANGE, message, **kwargs)
