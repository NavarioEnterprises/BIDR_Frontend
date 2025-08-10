"""
Utility functions and helpers for the BIDR Inventory Service.
"""

import hashlib
import secrets
from decimal import Decimal
from typing import Optional, Tuple
import math
from django.core.exceptions import ValidationError
from django.utils import timezone
from datetime import timedelta


def generate_reference_number(prefix: str = "", length: int = 8) -> str:
    """
    Generate a unique reference number with optional prefix.
    
    Args:
        prefix: Optional prefix for the reference number
        length: Length of the random part (default 8)
        
    Returns:
        A unique reference number string
    """
    random_part = secrets.token_hex(length // 2).upper()
    timestamp_part = str(int(timezone.now().timestamp()))[-4:]
    
    if prefix:
        return f"{prefix}-{timestamp_part}-{random_part}"
    return f"{timestamp_part}-{random_part}"


def calculate_distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate distance between two coordinate points in kilometers using Haversine formula.
    
    Args:
        lat1: Latitude of first point
        lon1: Longitude of first point
        lat2: Latitude of second point
        lon2: Longitude of second point
        
    Returns:
        Distance in kilometers as float
    """
    if not all([lat1, lon1, lat2, lon2]):
        return float('inf')
    
    # Convert latitude and longitude from degrees to radians
    lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
    
    # Haversine formula
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a))
    
    # Radius of Earth in kilometers
    r = 6371
    
    return c * r


def validate_coordinates(latitude: float, longitude: float) -> bool:
    """
    Validate geographic coordinates.
    
    Args:
        latitude: Latitude value
        longitude: Longitude value
        
    Returns:
        True if coordinates are valid, False otherwise
    """
    try:
        lat = float(latitude)
        lon = float(longitude)
        return -90 <= lat <= 90 and -180 <= lon <= 180
    except (ValueError, TypeError):
        return False


def calculate_platform_fee(amount: Decimal, fee_percentage: float = 5.0) -> Decimal:
    """
    Calculate platform fee based on transaction amount.
    
    Args:
        amount: Transaction amount
        fee_percentage: Fee percentage (default 5.0%)
        
    Returns:
        Platform fee amount
    """
    if amount < 0:
        raise ValidationError("Amount cannot be negative")
    
    fee = amount * Decimal(str(fee_percentage / 100))
    return fee.quantize(Decimal('0.01'))  # Round to 2 decimal places


def generate_secure_token(length: int = 32) -> str:
    """
    Generate a cryptographically secure random token.
    
    Args:
        length: Length of the token in bytes
        
    Returns:
        Hex-encoded secure token
    """
    return secrets.token_hex(length)


def hash_sensitive_data(data: str, salt: Optional[str] = None) -> Tuple[str, str]:
    """
    Hash sensitive data with salt for secure storage.
    
    Args:
        data: Data to hash
        salt: Optional salt (will generate if not provided)
        
    Returns:
        Tuple of (hashed_data, salt)
    """
    if salt is None:
        salt = secrets.token_hex(16)
    
    # Combine data and salt
    salted_data = f"{data}{salt}".encode('utf-8')
    
    # Create hash
    hash_obj = hashlib.sha256(salted_data)
    hashed_data = hash_obj.hexdigest()
    
    return hashed_data, salt


def verify_hashed_data(data: str, hashed_data: str, salt: str) -> bool:
    """
    Verify data against its hash.
    
    Args:
        data: Original data to verify
        hashed_data: Stored hash
        salt: Salt used for hashing
        
    Returns:
        True if data matches hash, False otherwise
    """
    new_hash, _ = hash_sensitive_data(data, salt)
    return new_hash == hashed_data


def format_currency(amount: Decimal, currency_code: str = "USD") -> str:
    """
    Format amount as currency string.
    
    Args:
        amount: Amount to format
        currency_code: Currency code (default USD)
        
    Returns:
        Formatted currency string
    """
    if currency_code == "USD":
        return f"${amount:,.2f}"
    elif currency_code == "EUR":
        return f"€{amount:,.2f}"
    elif currency_code == "GBP":
        return f"£{amount:,.2f}"
    else:
        return f"{currency_code} {amount:,.2f}"


def calculate_expiry_date(days: int = 30) -> timezone.datetime:
    """
    Calculate expiry date from current time.
    
    Args:
        days: Number of days from now
        
    Returns:
        Expiry datetime
    """
    return timezone.now() + timedelta(days=days)


def is_expired(expiry_date: timezone.datetime) -> bool:
    """
    Check if a date is in the past (expired).
    
    Args:
        expiry_date: Date to check
        
    Returns:
        True if expired, False otherwise
    """
    return timezone.now() > expiry_date


def paginate_queryset(queryset, page_size: int = 20, page: int = 1):
    """
    Simple pagination helper for querysets.
    
    Args:
        queryset: Django queryset to paginate
        page_size: Number of items per page
        page: Page number (1-based)
        
    Returns:
        Tuple of (paginated_queryset, has_next, has_previous, total_count)
    """
    total_count = queryset.count()
    start = (page - 1) * page_size
    end = start + page_size
    
    paginated_qs = queryset[start:end]
    
    has_next = end < total_count
    has_previous = page > 1
    
    return paginated_qs, has_next, has_previous, total_count


def clean_phone_number(phone: str) -> str:
    """
    Clean and format phone number.
    
    Args:
        phone: Raw phone number string
        
    Returns:
        Cleaned phone number
    """
    if not phone:
        return ""
    
    # Remove all non-digit characters except +
    cleaned = ''.join(char for char in phone if char.isdigit() or char == '+')
    
    # Ensure it starts with + for international format
    if cleaned and not cleaned.startswith('+'):
        cleaned = '+' + cleaned
    
    return cleaned


def truncate_text(text: str, max_length: int = 100, suffix: str = "...") -> str:
    """
    Truncate text to specified length with suffix.
    
    Args:
        text: Text to truncate
        max_length: Maximum length
        suffix: Suffix to append if truncated
        
    Returns:
        Truncated text
    """
    if not text or len(text) <= max_length:
        return text
    
    return text[:max_length - len(suffix)] + suffix
