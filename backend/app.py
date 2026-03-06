
from flask import Flask, request, jsonify, send_from_directory
import json
from flask_cors import CORS
import os
import datetime
from dotenv import load_dotenv

# Load env vars immediately
load_dotenv()

# Import our services
from db import users_service, diagnosis_service, calendar_db_service, community_service
from agri_calendar import calendar_service, scheduler, reminder_service
from doc_feature import pipeline
from location import location_service
from prediction import prediction_engine

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

@app.route('/')
def home():
    from db.firebase_init import FIREBASE_AVAILABLE
    status = "online"
    db_status = "connected" if FIREBASE_AVAILABLE else "disconnected"
    return jsonify({
        "status": status, 
        "message": "Krishi Vaidhya API is running on port 5001",
        "database": db_status
    })

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
        
    except ValueError as e:
        # Clean up temp file
        if os.path.exists(temp_path):
            os.remove(temp_path)
        
        # Handle specific validation errors with user-friendly messages
        error_msg = str(e)
        if "Confidence too low" in error_msg or "confidence" in error_msg.lower():
            return jsonify({
                "error": "Not a Plant Image",
                "message": "The uploaded image does not appear to be a clear plant/crop image. Please upload a photo showing plant leaves or affected areas clearly.",
                "suggestion": "Try taking a well-lit photo of the plant leaves or diseased area."
            }), 400
        else:
            return jsonify({"error": error_msg}), 400
            
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
    
    if not all([user_id, crop, sowing_date]) or lat is None or lng is None:
        return jsonify({"error": "Missing required fields"}), 400
    
    try:
        # Normalize location
        location = location_service.normalize_location(lat, lng)
        
        # Generate calendar
        calendar = calendar_service.generate_calendar(crop, sowing_date, location, user_id)
        
        # Run initial weather check
        calendar, _ = scheduler.auto_reschedule_calendar(calendar)
        
        # Save to DB
        calendar_id = calendar_db_service.save_calendar(calendar)
        
        # Convert datetime objects to strings for JSON serialization
        if "createdAt" in calendar and isinstance(calendar["createdAt"], datetime.datetime):
            calendar["createdAt"] = calendar["createdAt"].isoformat()
        if "updatedAt" in calendar and isinstance(calendar["updatedAt"], datetime.datetime):
            calendar["updatedAt"] = calendar["updatedAt"].isoformat()
        
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
    updated_calendar, evaluation = scheduler.auto_reschedule_calendar(calendar)
    
    # If changes were made, save them
    if evaluation["needsRescheduling"]:
        calendar_db_service.update_calendar(calendar_id, updated_calendar)
    
    return jsonify(updated_calendar)

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

# --- COMMUNITY ROUTES ---
@app.route('/api/community/posts', methods=['POST'])
def create_community_post():
    # Handle both JSON and Multipart
    if request.content_type and 'multipart/form-data' in request.content_type:
        user_id = request.form.get('userId')
        user_name = request.form.get('userName')
        content = request.form.get('content')
        lat = float(request.form.get('lat', 0.0))
        lng = float(request.form.get('lng', 0.0))
        analysis_data_raw = request.form.get('analysisData')
        analysis_data = json.loads(analysis_data_raw) if analysis_data_raw else None
        
        image_url = None
        if 'image' in request.files:
            image = request.files['image']
            if image.filename:
                # Create a unique filename
                filename = f"{user_id}_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}_{image.filename}"
                save_path = os.path.join('static', 'community_images', filename)
                
                # Ensure directory exists (redundant but safe)
                os.makedirs(os.path.dirname(save_path), exist_ok=True)
                
                image.save(save_path)
                image_url = f"/static/community_images/{filename}"
        
        if not user_id or not content:
            return jsonify({"error": "User ID and content required"}), 400
            
        post_id = community_service.create_post(user_id, content, lat, lng, image_url, analysis_data, user_name)
        return jsonify({"postId": post_id, "status": "success", "imageUrl": image_url})
    
    # Fallback to old JSON behavior
    data = request.json
    user_id = data.get('userId')
    user_name = data.get('userName')
    content = data.get('content')
    lat = float(data.get('lat', 0.0))
    lng = float(data.get('lng', 0.0))
    
    if not user_id or not content:
        return jsonify({"error": "User ID and content required"}), 400
        
    post_id = community_service.create_post(user_id, content, lat, lng, user_name=user_name)
    return jsonify({"postId": post_id, "status": "success"})

@app.route('/static/<path:path>')
def send_report(path):
    return send_from_directory('static', path)

@app.route('/api/community/posts', methods=['GET'])
def get_community_posts():
    limit = int(request.args.get('limit', 20))
    posts = community_service.get_posts(limit)
    return jsonify(posts)

@app.route('/api/community/posts/<post_id>/comment', methods=['POST'])
def add_community_comment(post_id):
    data = request.json
    user_id = data.get('userId')
    content = data.get('content')
    
    if not user_id or not content:
        return jsonify({"error": "User ID and content required"}), 400
        
    community_service.add_comment(post_id, user_id, content)
    return jsonify({"status": "success"})

@app.route('/api/community/posts/<post_id>/like', methods=['POST'])
def like_community_post(post_id):
    data = request.json
    user_id = data.get('userId')
    
    if not user_id:
        return jsonify({"error": "User ID required"}), 400
        
    community_service.like_post(post_id, user_id)
    return jsonify({"status": "success"})

# --- PREDICTIVE ANALYSIS ROUTES ---
@app.route('/api/prediction/alerts', methods=['POST'])
def get_prediction_alerts():
    """
    Generate predictive disease alerts for the user.

    Expects JSON:
        userId (str): Phone number
        lat (float): Latitude
        lng (float): Longitude
        crops (list[str], optional): Crops override

    Returns:
        { alerts, summary, weather, crops_monitored, generated_at }
    """
    data = request.json or {}
    user_id = data.get('userId')
    lat = data.get('lat')
    lng = data.get('lng')
    crops = data.get('crops')          # optional override

    if not user_id:
        return jsonify({"error": "userId required"}), 400
    if lat is None or lng is None:
        return jsonify({"error": "lat and lng required"}), 400

    try:
        # Resolve location names for better database matching
        district = None
        village = None
        try:
            loc = location_service.normalize_location(float(lat), float(lng))
            district = loc.get("district")
            village = loc.get("village")
        except Exception as loc_err:
            print(f"Location normalization skipped: {loc_err}")

        result = prediction_engine.generate_alerts(
            user_id=user_id,
            lat=float(lat),
            lng=float(lng),
            district=district,
            village=village,
            user_crops=crops,
        )
        return jsonify(result)

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

# --- WEATHER ROUTES ---
@app.route('/api/weather/current', methods=['GET'])
def get_current_weather():
    try:
        lat = request.args.get('lat', type=float)
        lng = request.args.get('lng', type=float)
        
        if lat is None or lng is None:
            # Default to Bangalore if no location provided
            lat = 12.9716
            lng = 77.5946
            
        from agri_calendar import weather_service
        forecast = weather_service.get_weather_forecast(lat, lng, days=1)
        
        if not forecast:
            return jsonify({"error": "Failed to fetch weather data"}), 500
            
        current = forecast.get('current', {})
        location = forecast.get('location', {})
        
        return jsonify({
            "temp_c": current.get('temp_c'),
            "condition": current.get('condition', {}).get('text'),
            "icon": current.get('condition', {}).get('icon'),
            "humidity": current.get('humidity'),
            "wind_kph": current.get('wind_kph'),
            "location": location.get('name'),
            "region": location.get('region')
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Use PORT env var (set by Railway/cloud) or fallback to 5001 for local dev
    port = int(os.environ.get('PORT', 5001))
    debug = os.environ.get('FLASK_ENV', 'production') == 'development'
    app.run(host='0.0.0.0', port=port, debug=debug)
