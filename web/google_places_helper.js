// Google Places API helper for Flutter web
let autocompleteService = null;
let placesService = null;
let isGoogleMapsLoaded = false;

// Initialize the Google Places service
function initializePlacesService() {
    console.log('Initializing Places Service...');
    if (typeof google !== 'undefined' && google.maps && google.maps.places) {
        try {
            autocompleteService = new google.maps.places.AutocompleteService();
            // Create a temporary div for PlacesService (required by API)
            const tempDiv = document.createElement('div');
            const map = new google.maps.Map(tempDiv, {
                center: { lat: -26.2041, lng: 28.0473 }, // Johannesburg
                zoom: 10
            });
            placesService = new google.maps.places.PlacesService(map);
            isGoogleMapsLoaded = true;
            console.log('Places Service initialized successfully');
            return true;
        } catch (error) {
            console.error('Error initializing Places Service:', error);
            return false;
        }
    }
    console.log('Google Maps API not available yet');
    return false;
}

// Get place predictions using Google Places JavaScript API
function getPlacePredictions(input, callback) {
    if (!autocompleteService) {
        if (!initializePlacesService()) {
            callback([]);
            return;
        }
    }

    if (!input || input.length < 2) {
        callback([]);
        return;
    }

    const request = {
        input: input,
        componentRestrictions: { country: 'za' },
        types: ['geocode'] // Using only geocode to avoid conflicts
    };

    autocompleteService.getPlacePredictions(request, function(predictions, status) {
        if (status === google.maps.places.PlacesServiceStatus.OK && predictions) {
            const results = predictions.slice(0, 8).map(function(prediction) {
                // Convert to plain JavaScript object to avoid JsObject issues
                const plainObject = JSON.parse(JSON.stringify({
                    description: prediction.description || '',
                    placeId: prediction.place_id || '',
                    reference: prediction.reference || '',
                    types: Array.isArray(prediction.types) ? prediction.types : [],
                    structured_formatting: prediction.structured_formatting ? {
                        main_text: prediction.structured_formatting.main_text || '',
                        secondary_text: prediction.structured_formatting.secondary_text || ''
                    } : null
                }));
                return plainObject;
            });
            callback(results);
        } else {
            console.log('Places service status:', status);
            callback([]);
        }
    });
}

// Get place details by place ID
function getPlaceDetails(placeId, callback) {
    if (!placesService) {
        if (!initializePlacesService()) {
            callback(null);
            return;
        }
    }

    const request = {
        placeId: placeId,
        fields: ['place_id', 'formatted_address', 'geometry.location', 'name', 'types']
    };

    placesService.getDetails(request, function(place, status) {
        if (status === google.maps.places.PlacesServiceStatus.OK && place) {
            // Convert to plain JavaScript object to avoid JsObject issues
            const result = JSON.parse(JSON.stringify({
                placeId: place.place_id || '',
                formattedAddress: place.formatted_address || '',
                name: place.name || '',
                types: Array.isArray(place.types) ? place.types : [],
                latitude: place.geometry && place.geometry.location ? 
                    place.geometry.location.lat() : 0,
                longitude: place.geometry && place.geometry.location ? 
                    place.geometry.location.lng() : 0
            }));
            callback(result);
        } else {
            console.log('Place details status:', status);
            callback(null);
        }
    });
}

// Geocode an address
function geocodeAddress(address, callback) {
    if (typeof google === 'undefined' || !google.maps) {
        callback([]);
        return;
    }

    const geocoder = new google.maps.Geocoder();
    const request = {
        address: address,
        componentRestrictions: { country: 'ZA' }
    };

    geocoder.geocode(request, function(results, status) {
        if (status === google.maps.GeocoderStatus.OK && results) {
            const geocodeResults = results.slice(0, 5).map(function(result) {
                // Convert to plain JavaScript object to avoid JsObject issues
                const plainObject = JSON.parse(JSON.stringify({
                    formattedAddress: result.formatted_address || '',
                    latitude: result.geometry.location.lat(),
                    longitude: result.geometry.location.lng(),
                    types: Array.isArray(result.types) ? result.types : []
                }));
                return plainObject;
            });
            callback(geocodeResults);
        } else {
            console.log('Geocoding status:', status);
            callback([]);
        }
    });
}

// Wait for Google Maps to load
function waitForGoogleMaps(callback, maxAttempts = 100) {
    let attempts = 0;
    
    function checkGoogleMaps() {
        attempts++;
        console.log(`Checking Google Maps availability, attempt ${attempts}`);
        if (typeof google !== 'undefined' && google.maps && google.maps.places) {
            console.log('Google Maps API detected, initializing...');
            if (initializePlacesService()) {
                callback(true);
            } else {
                setTimeout(checkGoogleMaps, 200);
            }
        } else if (attempts < maxAttempts) {
            setTimeout(checkGoogleMaps, 200);
        } else {
            console.error('Google Maps API failed to load after maximum attempts');
            callback(false);
        }
    }
    
    checkGoogleMaps();
}

// Expose functions to global window object for Flutter to access
window.getPlacePredictions = getPlacePredictions;
window.getPlaceDetails = getPlaceDetails;
window.geocodeAddress = geocodeAddress;
window.waitForGoogleMaps = waitForGoogleMaps;
window.initializePlacesService = initializePlacesService;

// Initialize when the page loads
document.addEventListener('DOMContentLoaded', function() {
    console.log('DOM loaded, waiting for Google Maps...');
    waitForGoogleMaps(function(success) {
        if (success) {
            console.log('Google Places API ready for use');
        } else {
            console.error('Failed to initialize Google Places API');
        }
    });
});

// Also try to initialize when the script loads
if (document.readyState === 'loading') {
    // DOM is still loading
    document.addEventListener('DOMContentLoaded', function() {
        setTimeout(() => {
            console.log('Attempting late initialization...');
            waitForGoogleMaps(function(success) {
                console.log('Late initialization result:', success);
            });
        }, 1000);
    });
} else {
    // DOM is already loaded
    setTimeout(() => {
        console.log('Attempting immediate initialization...');
        waitForGoogleMaps(function(success) {
            console.log('Immediate initialization result:', success);
        });
    }, 1000);
}