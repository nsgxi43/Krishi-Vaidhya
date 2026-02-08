# kvb/location/location_service.py
import os
import requests
try:
    import geohash as gh
except ImportError:
    try:
        import Geohash as gh
    except ImportError:
        gh = None
        print("Geohash library not available. Location services restricted.")
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

GOOGLE_MAPS_KEY = os.getenv("GOOGLE_MAPS_API_KEY")

GEOCODE_URL = "https://maps.googleapis.com/maps/api/geocode/json"
PLACE_URL = "https://maps.googleapis.com/maps/api/place/details/json"
NEARBY_SEARCH_URL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"


def reverse_geocode(lat: float, lng: float) -> dict:
    """Call Google Geocoding API to get address components."""
    if not GOOGLE_MAPS_KEY:
        print("Google Maps API Key not set. Returning mock geocode.")
        return {
            "status": "OK",
            "results": [{
                "address_components": [
                    {"long_name": "Mock Village", "types": ["locality"]},
                    {"long_name": "Mock District", "types": ["administrative_area_level_3"]},
                    {"long_name": "Mock State", "types": ["administrative_area_level_1"]}
                ],
                "geometry": {
                    "location": {"lat": lat, "lng": lng}
                }
            }]
        }

    params = {
        "latlng": f"{lat},{lng}",
        "key": GOOGLE_MAPS_KEY
    }
    res = requests.get(GEOCODE_URL, params=params, timeout=10)
    res.raise_for_status()
    return res.json()


def place_details(place_id: str) -> dict:
    """Get detailed information about a place."""
    if not GOOGLE_MAPS_KEY:
        return {}

    params = {
        "place_id": place_id,
        "fields": "name,geometry,address_component,rating,website",
        "key": GOOGLE_MAPS_KEY
    }
    res = requests.get(PLACE_URL, params=params, timeout=10)
    res.raise_for_status()
    return res.json()


def nearby_search(lat: float, lng: float, radius_m: int, keyword: str, place_type: str = "store") -> dict:
    """Search for nearby places using Google Places API."""
    if not GOOGLE_MAPS_KEY:
        print("Google Maps API Key not set. Returning mock places.")
        return {
            "status": "OK",
            "results": [
                {
                    "name": "Kisan Seva Kendra", 
                    "vicinity": "Main Market, Bangalore", 
                    "rating": 4.5,
                    "geometry": {"location": {"lat": lat + 0.01, "lng": lng + 0.01}}
                },
                {
                    "name": "Agri-Tech Solutions", 
                    "vicinity": "Electronic City, Bangalore", 
                    "rating": 4.2,
                    "geometry": {"location": {"lat": lat - 0.01, "lng": lng - 0.01}}
                },
                {
                    "name": "Green Earth Fertilizers", 
                    "vicinity": "MG Road, Bangalore", 
                    "rating": 4.8,
                    "geometry": {"location": {"lat": lat + 0.02, "lng": lng - 0.01}}
                }
            ]
        }

    params = {
        "location": f"{lat},{lng}",
        "radius": radius_m,
        "type": place_type,
        "keyword": keyword,
        "key": GOOGLE_MAPS_KEY
    }
    res = requests.get(NEARBY_SEARCH_URL, params=params, timeout=10)
    res.raise_for_status()
    return res.json()


def extract_location_components(geo_json: dict) -> dict:
    """
    Extract state, district, village from Google Geocoding response.
    Returns dict with state, district, village (or None if not found).
    """
    if geo_json.get("status") != "OK":
        raise ValueError(f"Geocoding failed: {geo_json.get('status')}")
    
    results = geo_json.get("results", [])
    if not results:
        raise ValueError("No geocoding results returned")
    
    components = results[0].get("address_components", [])
    
    state = None
    district = None
    village = None
    
    for component in components:
        types = component.get("types", [])
        name = component.get("long_name")
        
        if "administrative_area_level_1" in types:
            state = name
        elif "administrative_area_level_3" in types:
            district = name
        elif "locality" in types or "sublocality" in types:
            if not village:  # Use first locality found
                village = name
    
    return {
        "state": state,
        "district": district,
        "village": village
    }


def normalize_location(lat: float, lng: float) -> dict:
    """
    Normalize location to standard format.
    This is the SINGLE SOURCE OF TRUTH for location data.
    
    Returns:
    {
        "lat": float,
        "lng": float,
        "state": str | None,
        "district": str | None,
        "village": str | None,
        "geohash": str
    }
    """
    try:
        # Reverse geocode using Google API
        geo_json = reverse_geocode(lat, lng)
        
        # Extract components
        location = extract_location_components(geo_json)
        
        # Generate geohash (precision 5 ≈ 4.9km x 4.9km)
        if gh:
            geohash_str = gh.encode(lat, lng, precision=5)
        else:
            geohash_str = "00000"
        
        return {
            "lat": lat,
            "lng": lng,
            "state": location["state"],
            "district": location["district"],
            "village": location["village"],
            "geohash": geohash_str
        }
    
    except Exception as e:
        # Fail safely - return minimal location with geohash
        print(f"Location normalization failed: {e}")
        return {
            "lat": lat,
            "lng": lng,
            "state": None,
            "district": None,
            "village": None,
            "village": None,
            "geohash": gh.encode(lat, lng, precision=5) if gh else "00000"
        }