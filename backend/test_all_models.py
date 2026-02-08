
import os
import requests
import json
import base64
from dotenv import load_dotenv

load_dotenv()
API_KEY = os.getenv("GEMINI_API_KEY")

MODELS_TO_TEST = [
    "gemini-2.0-flash-lite",
    "gemini-2.0-flash",
    "gemini-1.5-flash",
    "gemini-1.5-flash-8b",
    "gemini-pro-vision"
]

IMAGE_PATH = os.path.join("backend", "doc_feature", "test_image.jpg")
if not os.path.exists(IMAGE_PATH):
    # Try alternate path
    IMAGE_PATH = os.path.join("doc_feature", "test_image.jpg")

with open(IMAGE_PATH, "rb") as f:
    img_data = base64.b64encode(f.read()).decode("utf-8")

for model in MODELS_TO_TEST:
    print(f"\n--- Testing Model: {model} ---")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={API_KEY}"
    
    payload = {
        "contents": [{
            "parts": [
                {"text": "Is this a healthy plant? Answer in 5 words."},
                {"inline_data": {"mime_type": "image/jpeg", "data": img_data}}
            ]
        }]
    }
    
    try:
        response = requests.post(url, json=payload, timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            print("Response:", response.json().get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "No text"))
        else:
            print("Error:", response.text)
    except Exception as e:
        print("Exception:", e)
