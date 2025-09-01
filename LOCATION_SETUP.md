# Location Services Setup

This document explains how to set up and use the location services for converting coordinates to addresses.

## Features

1. **Automatic Address Conversion**: When coordinates are provided without a physical address, the system automatically converts them to a readable address
2. **API Endpoint**: Dedicated endpoint for coordinate-to-address conversion
3. **Fallback Handling**: Gracefully handles API failures by displaying coordinates

## Setup Instructions

### 1. Google Maps API Key

To enable address lookup from coordinates, you need a Google Maps API key:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Geocoding API**
4. Create credentials (API Key)
5. Add the API key to your environment

### 2. Environment Configuration

Add your API key to your `.env` file:

```bash
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

### 3. Install Required Packages

The `requests` library is required for API calls:

```bash
pip install requests
```

## API Usage

### Geocoding Endpoint

Convert coordinates to addresses using the new geocoding endpoint:

**POST** `/seller/geocode/`
```json
{
    "latitude": -17.8292,
    "longitude": 31.0522
}
```

**GET** `/seller/geocode/?lat=-17.8292&lng=31.0522`

**Response:**
```json
{
    "latitude": -17.8292,
    "longitude": 31.0522,
    "formatted_address": "123 Main Street, Harare, Zimbabwe",
    "display_text": "123 Main Street, Harare, Zimbabwe"
}
```

### Business Registration with Coordinates

When submitting business registration with coordinates, the system automatically converts them:

```json
{
    "auth_user_id": "...",
    "contact_info": {
        "latitude": -17.8292,
        "longitude": 31.0522,
        "contact_person_name": "John Doe",
        "contact_person_telephone": "+263123456789",
        "contact_person_email": "john@example.com",
        "platform_workflow_email": "workflow@example.com"
    }
}
```

The `physical_address` and `location_address` fields will be automatically populated with the geocoded address.

## Frontend Integration

### For Web Applications

```javascript
// Function to get address from coordinates
async function getAddressFromCoordinates(lat, lng) {
    try {
        const response = await fetch('/seller/geocode/', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                latitude: lat,
                longitude: lng
            })
        });
        
        const data = await response.json();
        return data.display_text; // This is the formatted address
    } catch (error) {
        console.error('Error getting address:', error);
        return `Location: ${lat}, ${lng}`; // Fallback
    }
}

// Usage when user selects a location pin
map.on('click', async function(event) {
    const { lat, lng } = event.latlng;
    const address = await getAddressFromCoordinates(lat, lng);
    
    // Display address instead of coordinates
    document.getElementById('location-display').textContent = address;
    
    // Store coordinates for form submission
    document.getElementById('latitude').value = lat;
    document.getElementById('longitude').value = lng;
    document.getElementById('physical_address').value = address;
});
```

### For Mobile Applications (Flutter/React Native)

```dart
// Flutter example
Future<String> getAddressFromCoordinates(double lat, double lng) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/seller/geocode/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'latitude': lat,
        'longitude': lng,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['display_text'];
    }
  } catch (e) {
    print('Error getting address: $e');
  }
  
  return 'Location: $lat, $lng'; // Fallback
}
```

## Error Handling

The system includes comprehensive error handling:

1. **No API Key**: Falls back to displaying coordinates
2. **API Failure**: Falls back to displaying coordinates
3. **Invalid Coordinates**: Returns error message
4. **Network Issues**: Gracefully handles timeouts and connection errors

## Security Considerations

1. **API Key Protection**: Store the Google Maps API key in environment variables, never in code
2. **Rate Limiting**: Google Maps API has usage limits and costs
3. **Input Validation**: Coordinates are validated for proper ranges
4. **Error Logging**: Failed geocoding attempts are logged for monitoring

## Testing

Test the geocoding functionality:

```bash
# Test with POST request
curl -X POST http://localhost:8000/seller/geocode/ \
  -H "Content-Type: application/json" \
  -d '{"latitude": -17.8292, "longitude": 31.0522}'

# Test with GET request
curl "http://localhost:8000/seller/geocode/?lat=-17.8292&lng=31.0522"
```

## Troubleshooting

1. **"Location: lat, lng" displayed**: API key not configured or geocoding failed
2. **500 errors**: Check API key validity and quotas
3. **Timeout errors**: Network connectivity issues or slow API response

## Cost Considerations

Google Maps Geocoding API pricing:
- $5 per 1,000 requests
- First $200 per month is free (40,000 requests)
- Consider implementing caching for frequently requested locations