
import requests
import json

BASE_URL = "http://127.0.0.1:5000"

def test_fetch_stores():
    url = f"{BASE_URL}/api/stores"
    data = {
        "lat": 12.9716, 
        "lng": 77.5946
    }
    
    print(f"Testing {url} with data {data}")
    
    try:
        response = requests.post(url, json=data)
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            stores = response.json()
            print(f"Found {len(stores)} stores")
            if len(stores) > 0:
                print(f"First store: {stores[0]['name']} ({stores[0]['distance_km']} km)")
            else:
                print("No stores found (Check Google Maps API Key)")
        else:
            print(f"Error: {response.text}")
            
    except Exception as e:
        print(f"Request failed: {e}")

if __name__ == "__main__":
    test_fetch_stores()
