from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import datetime
from dotenv import load_dotenv

# Load env vars immediately
load_dotenv()

# Import our services
from db import users_service, diagnosis_service, calendar_db_service
from agri_calendar import calendar_service, scheduler, reminder_service
from doc_feature import pipeline
from location import location_service

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

@app.route('/')
def home():
    return jsonify({"status": "online", "message": "Krishi Vaidhya API is running"})

# --- USER ROUTES ---
@app.route('/api/users/login', methods=['POST'])
def login_user():
    data = request.json
    phone = data.get('phone')
    name = data.get('name', 'Farmer')
    language = data.get('language', 'en')
    crops = data.get('crops', [])
    
    if not phone:
        return jsonify({"error": "Phone number required"}), 400
        
    result = users_service.upsert_user(phone, name, language, crops)
    return jsonify(result)

# --- DIAGNOSIS ROUTES ---
@app.route('/api/diagnosis', methods=['POST'])
def diagnose_crop():
    if 'image' not in request.files:
        return jsonify({"error": "No image file provided"}), 400
        
    image = request.files['image']
    user_id = request.form.get('userId')
    lat = float(request.form.get('lat', 0.0))
    lng = float(request.form.get('lng', 0.0))
    
    if not user_id:
        return jsonify({"error": "User ID required"}), 400
        
    # Save temp file
    temp_path = f"temp_{image.filename}"
    image.save(temp_path)
    
    try:
        # Run AI Pipeline
        result = pipeline.run_pipeline(temp_path, user_id, lat, lng)
        
        # Clean up
        if os.path.exists(temp_path):
            os.remove(temp_path)
            
        return jsonify(result)
        
    except Exception as e:
        if os.path.exists(temp_path):
            os.remove(temp_path)
        return jsonify({"error": str(e)}), 500

# --- CALENDAR ROUTES ---
@app.route('/api/calendar/generate', methods=['POST'])
def generate_calendar():
    data = request.json
    user_id = data.get('userId')
    crop = data.get('crop')
    sowing_date = data.get('sowingDate')
    lat = data.get('lat')
    lng = data.get('lng')
    
    if not all([user_id, crop, sowing_date, lat, lng]):
        return jsonify({"error": "Missing required fields"}), 400
    
    try:
        # Normalize location
        location = location_service.normalize_location(lat, lng)
        
        # Generate calendar
        calendar = calendar_service.generate_calendar(crop, sowing_date, location, user_id)
        
        # Save to DB
        calendar_id = calendar_db_service.save_calendar(calendar)
        
        return jsonify({"calendarId": calendar_id, "calendar": calendar})
        
    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/calendar/<calendar_id>', methods=['GET'])
def get_calendar(calendar_id):
    calendar = calendar_db_service.get_calendar(calendar_id)
    if not calendar:
        return jsonify({"error": "Calendar not found"}), 404
        
    # Check for weather updates/rescheduling
    weather_update, _ = scheduler.auto_reschedule_calendar(calendar)
    
    
    return jsonify(weather_update)

# --- STORE ROUTES ---
@app.route('/api/stores', methods=['POST'])
def get_stores():
    data = request.json
    lat = data.get('lat')
    lng = data.get('lng')
    
    if not lat or not lng:
        return jsonify({"error": "Location required"}), 400
        
    try:
        from doc_feature import agri_store_service
        # Normalize
        location = location_service.normalize_location(lat, lng)
        stores = agri_store_service.get_nearby_agri_stores(location, radius_km=10)
        return jsonify(stores)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
