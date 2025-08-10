"""
Custom exception handlers for the BIDR Inventory Service.
"""

import logging
from django.core.exceptions import ValidationError as DjangoValidationError
from django.http import Http404
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import exception_handler
from rest_framework.exceptions import (
    ValidationError,
    NotFound,
    PermissionDenied,
    AuthenticationFailed,
    Throttled
)

logger = logging.getLogger(__name__)


class InventoryServiceException(Exception):
    """Base exception for inventory service specific errors."""
    default_message = "An error occurred in the inventory service"
    default_code = "inventory_error"
    
    def __init__(self, message=None, code=None, details=None):
        self.message = message or self.default_message
        self.code = code or self.default_code
        self.details = details or {}
        super().__init__(self.message)


class ProductNotAvailableException(InventoryServiceException):
    """Raised when a product is not available for the requested operation."""
    default_message = "Product is not available"
    default_code = "product_not_available"


class InsufficientInventoryException(InventoryServiceException):
    """Raised when there is insufficient inventory for the requested quantity."""
    default_message = "Insufficient inventory available"
    default_code = "insufficient_inventory"


class QuoteExpiredException(InventoryServiceException):
    """Raised when attempting to use an expired quote."""
    default_message = "Quote has expired"
    default_code = "quote_expired"


class RequestExpiredException(InventoryServiceException):
    """Raised when attempting to operate on an expired request."""
    default_message = "Request has expired"
    default_code = "request_expired"


class PaymentRequiredException(InventoryServiceException):
    """Raised when payment is required before proceeding."""
    default_message = "Payment is required to complete this action"
    default_code = "payment_required"


class LocationOutOfRangeException(InventoryServiceException):
    """Raised when location is outside the service area."""
    default_message = "Location is outside the service area"
    default_code = "location_out_of_range"


class DuplicateTransactionException(InventoryServiceException):
    """Raised when attempting to create a duplicate transaction."""
    default_message = "Transaction already exists"
    default_code = "duplicate_transaction"


def custom_exception_handler(exc, context):
    """
    Custom exception handler that returns JSON responses for all exceptions.
    """
    # Call REST framework's default exception handler first
    response = exception_handler(exc, context)
    
    # Custom handling for our service exceptions
    if isinstance(exc, InventoryServiceException):
        custom_response_data = {
            'error': {
                'code': exc.code,
                'message': exc.message,
                'details': exc.details
            }
        }
        
        # Map exception types to HTTP status codes
        status_code_map = {
            ProductNotAvailableException: status.HTTP_409_CONFLICT,
            InsufficientInventoryException: status.HTTP_409_CONFLICT,
            QuoteExpiredException: status.HTTP_410_GONE,
            RequestExpiredException: status.HTTP_410_GONE,
            PaymentRequiredException: status.HTTP_402_PAYMENT_REQUIRED,
            LocationOutOfRangeException: status.HTTP_400_BAD_REQUEST,
            DuplicateTransactionException: status.HTTP_409_CONFLICT,
        }
        
        status_code = status_code_map.get(type(exc), status.HTTP_400_BAD_REQUEST)
        
        # Log the exception
        logger.warning(
            f"Inventory service exception: {exc.code} - {exc.message}",
            extra={
                'exception_type': type(exc).__name__,
                'code': exc.code,
                'details': exc.details,
                'context': context
            }
        )
        
        return Response(custom_response_data, status=status_code)
    
    # Handle Django validation errors
    if isinstance(exc, DjangoValidationError):
        custom_response_data = {
            'error': {
                'code': 'validation_error',
                'message': 'Validation failed',
                'details': {
                    'validation_errors': exc.message_dict if hasattr(exc, 'message_dict') else [str(exc)]
                }
            }
        }
        return Response(custom_response_data, status=status.HTTP_400_BAD_REQUEST)
    
    # If response is None, it means the exception wasn't handled by DRF
    if response is None:
        # Handle generic exceptions
        if isinstance(exc, Http404):
            custom_response_data = {
                'error': {
                    'code': 'not_found',
                    'message': 'The requested resource was not found',
                    'details': {}
                }
            }
            return Response(custom_response_data, status=status.HTTP_404_NOT_FOUND)
        
        # Log unexpected exceptions
        logger.error(
            f"Unhandled exception: {type(exc).__name__} - {str(exc)}",
            exc_info=True,
            extra={'context': context}
        )
        
        # Return generic error response for unhandled exceptions
        custom_response_data = {
            'error': {
                'code': 'internal_server_error',
                'message': 'An unexpected error occurred',
                'details': {}
            }
        }
        return Response(custom_response_data, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    # Customize the response data for DRF exceptions
    if response is not None:
        custom_response_data = {
            'error': {
                'code': 'client_error',
                'message': 'Request could not be processed',
                'details': response.data
            }
        }
        
        # Specific handling for common DRF exceptions
        if isinstance(exc, ValidationError):
            custom_response_data['error']['code'] = 'validation_error'
            custom_response_data['error']['message'] = 'Validation failed'
        elif isinstance(exc, NotFound):
            custom_response_data['error']['code'] = 'not_found'
            custom_response_data['error']['message'] = 'Resource not found'
        elif isinstance(exc, PermissionDenied):
            custom_response_data['error']['code'] = 'permission_denied'
            custom_response_data['error']['message'] = 'You do not have permission to perform this action'
        elif isinstance(exc, AuthenticationFailed):
            custom_response_data['error']['code'] = 'authentication_failed'
            custom_response_data['error']['message'] = 'Authentication credentials were not provided or are invalid'
        elif isinstance(exc, Throttled):
            custom_response_data['error']['code'] = 'throttled'
            custom_response_data['error']['message'] = f'Request was throttled. Try again in {exc.wait} seconds.'
            custom_response_data['error']['details'] = {
                'wait_time': exc.wait,
                'throttle_scope': getattr(exc, 'scope', None)
            }
        
        response.data = custom_response_data
    
    return response
