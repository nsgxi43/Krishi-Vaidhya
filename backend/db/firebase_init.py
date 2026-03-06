import os
import json

# Try to import firebase_admin, handle failure gracefully
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    FIREBASE_AVAILABLE = True
except ImportError as e:
    print(f"Firebase Admin SDK not available or missing dependencies: {e}")
    FIREBASE_AVAILABLE = False
    firebase_admin = None
    firestore = None
    credentials = None

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
KEY_PATH = os.path.join(BASE_DIR, "firebase-key.json")

# Prevent double initialization
if FIREBASE_AVAILABLE and not firebase_admin._apps:
    # Option 1: FIREBASE_KEY_JSON env var (Railway / cloud deployment)
    firebase_key_json = os.environ.get('FIREBASE_KEY_JSON')
    if firebase_key_json:
        try:
            key_dict = json.loads(firebase_key_json)
            cred = credentials.Certificate(key_dict)
            firebase_admin.initialize_app(cred)
            print("Firebase initialized from FIREBASE_KEY_JSON environment variable.")
        except Exception as e:
            print(f"Failed to initialize Firebase from env var: {e}")
    # Option 2: Local file (development)
    elif os.path.exists(KEY_PATH):
        try:
            cred = credentials.Certificate(KEY_PATH)
            firebase_admin.initialize_app(cred)
            print("Firebase initialized successfully from local key file.")
        except Exception as e:
            print(f"Failed to initialize Firebase: {e}")
    else:
        print(f"Firebase key not found (no env var, no file at {KEY_PATH}). DB operations disabled.")

try:
    if FIREBASE_AVAILABLE and firebase_admin._apps:
        db = firestore.client()
    else:
        print("Firebase not initialized. Using Mock/None for db.")
        db = None
except Exception as e:
    print(f"Error creating Firestore client: {e}")
    db = None

