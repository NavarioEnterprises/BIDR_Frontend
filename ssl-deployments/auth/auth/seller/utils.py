import requests
import logging
from django.conf import settings


logger = logging.getLogger(__name__)


def reverse_geocode(latitude, longitude, api_key=None):
    """
    Convert coordinates to a readable address using Google Maps Geocoding API
    
    Args:
        latitude (float): Latitude coordinate
        longitude (float): Longitude coordinate  
        api_key (str): Google Maps API key (optional, can be set in settings)
        
    Returns:
        str: Formatted address or coordinates if geocoding fails
    """
    if not api_key:
        api_key = getattr(settings, 'GOOGLE_MAPS_API_KEY', None)
    
    if not api_key:
        logger.warning("No Google Maps API key provided for reverse geocoding")
        return f"Location: {latitude}, {longitude}"
    
    try:
        url = f"https://maps.googleapis.com/maps/api/geocode/json"
        params = {
            'latlng': f"{latitude},{longitude}",
            'key': api_key
        }
        
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        
        data = response.json()
        
        if data['status'] == 'OK' and data['results']:
            # Return the most detailed address (first result)
            return data['results'][0]['formatted_address']
        else:
            logger.warning(f"Geocoding failed with status: {data.get('status', 'Unknown')}")
            
    except requests.exceptions.RequestException as e:
        logger.error(f"Error calling Google Maps API: {str(e)}")
    except Exception as e:
        logger.error(f"Unexpected error in reverse geocoding: {str(e)}")
    
    # Fallback to coordinates if geocoding fails
    return f"Location: {latitude}, {longitude}"


def format_location_with_address(latitude, longitude, api_key=None):
    """
    Format location data with both coordinates and human-readable address
    
    Returns:
        dict: Contains both coordinates and formatted address
    """
    address = reverse_geocode(latitude, longitude, api_key)
    
    return {
        'latitude': latitude,
        'longitude': longitude,
        'formatted_address': address,
        'display_text': address  # This is what should be shown in the UI
    }


def parse_location_data(location_input):
    """
    Parse various location input formats and return standardized location data
    
    Args:
        location_input: Can be dict with lat/lng, string address, or coordinates
        
    Returns:
        dict: Standardized location data with address
    """
    if isinstance(location_input, dict):
        lat = location_input.get('lat') or location_input.get('latitude')
        lng = location_input.get('lng') or location_input.get('longitude')
        
        if lat and lng:
            return format_location_with_address(float(lat), float(lng))
    
    return None