import os
import requests
import json
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("GEMINI_API_KEY")
print(f"API Key present: {bool(API_KEY)}")
if API_KEY:
    print(f"API Key start: {API_KEY[:5]}...")


API_URL = "https://generativelanguage.googleapis.com/v1beta/models"

try:
    print(f"Listing models from {API_URL}...")
    response = requests.get(
        f"{API_URL}?key={API_KEY}",
        timeout=10
    )
    
    print(f"Status Code: {response.status_code}")
    if response.status_code == 200:
        print("Available Models:")
        models = response.json().get('models', [])
        for m in models:
            print(f"- {m['name']}")
    else:
        print("Error:")
        print(response.text)

except Exception as e:
    print(f"Exception: {e}")
