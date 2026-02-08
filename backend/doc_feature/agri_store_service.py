# kvb/doc_feature/agri_store_service.py
"""
Agri Store Suggestions Service
Fetches nearby agricultural stores using Google Places API.
"""

import math
from location.location_service import nearby_search  # type: ignore


def calculate_distance(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """
    Calculate distance between two lat/lng points using Haversine formula.
    Returns distance in kilometers.
    """
    R = 6371  # Earth's radius in km
    
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    delta_lat = math.radians(lat2 - lat1)
    delta_lng = math.radians(lng2 - lng1)
    
    a = (math.sin(delta_lat / 2) ** 2 +
         math.cos(lat1_rad) * math.cos(lat2_rad) *
         math.sin(delta_lng / 2) ** 2)
    
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    
    return R * c


def get_nearby_agri_stores(location: dict, radius_km: int = 10) -> list:
    """
    Get nearby agricultural stores using Google Places API.
    
    Args:
        location: Normalized location dict with lat, lng
        radius_km: Search radius in kilometers (default 10)
    
    Returns:
        List of agri stores with name, distance, rating, maps_url
    """
    lat = location["lat"]
    lng = location["lng"]
    radius_m = radius_km * 1000  # Convert to meters
    
    stores = []
    
    # Search keywords for agricultural stores
    keywords = ["fertilizer", "agrovet", "pesticide", "agriculture supply", "farming"]
    
    try:
        for keyword in keywords:
            result = nearby_search(lat, lng, radius_m, keyword, place_type="store")
            
            if result.get("status") == "OK":
                for place in result.get("results", [])[:5]:  # Limit per keyword
                    place_lat = place["geometry"]["location"]["lat"]
                    place_lng = place["geometry"]["location"]["lng"]
                    
                    distance = calculate_distance(lat, lng, place_lat, place_lng)
                    
                    store = {
                        "name": place.get("name"),
                        "distance_km": round(distance, 2),  # type: ignore
                        "rating": place.get("rating"),
                        "maps_url": f"https://maps.google.com/?q={place_lat},{place_lng}",
                        "address": place.get("vicinity")
                    }
                    
                    # Avoid duplicates based on name
                    if not any(s["name"] == store["name"] for s in stores):
                        stores.append(store)
        
        # Sort by distance
        stores.sort(key=lambda x: x["distance_km"])
        
        # Return top 10
        return stores[:10]  # type: ignore
    
    except Exception as e:
        print(f"Failed to fetch agri stores: {e}")
        return []