# kvb/prediction/prediction_engine.py
"""
Predictive Analysis Engine — Enterprise-grade disease risk assessment.

Combines:
  1. Community diagnosis records (Firestore: diagnoses collection)
  2. Community posts with analysis data (Firestore: community collection)
  3. Real-time weather conditions (WeatherAPI)
  4. Gemini LLM for communicability & risk reasoning

Flow:
  user_crops × nearby_diagnoses × weather → per-crop risk alerts
"""

import os
import json
import math
import requests
from datetime import datetime, timedelta
from typing import List, Dict, Optional

from db.firebase_init import db
from agri_calendar.weather_service import get_weather_forecast

# ── Gemini config (reuse from doc_feature) ────────────────────────────
GEMINI_MODELS = ["gemini-2.0-flash", "gemini-2.5-flash", "gemini-1.5-flash"]
API_BASE = "https://generativelanguage.googleapis.com/v1beta/models"


def _get_gemini_key() -> str:
    """Always read from environment at call time (never cached at import time)."""
    return os.getenv("GEMINI_API_KEY", "")

# ── Search parameters ─────────────────────────────────────────────────
DEFAULT_RADIUS_KM = 25          # Lookup radius for nearby diagnoses
DEFAULT_LOOKBACK_DAYS = 30      # How far back to search
MIN_CASES_FOR_ALERT = 1         # Minimum cases to trigger an alert
HIGH_RISK_THRESHOLD = 0.65
MEDIUM_RISK_THRESHOLD = 0.35

# ── Distance decay constant (epidemiology standard) ───────────────────
# Weight = e^(-distance / DECAY_CONSTANT)
# At 10km: weight ≈ 0.37, At 20km: weight ≈ 0.14, At 25km: weight ≈ 0.08
DISTANCE_DECAY_CONSTANT = 10.0

# ── Risk formula weights ──────────────────────────────────────────────
# risk = base * (1 + WEATHER_WEIGHT*weather_mult + SEVERITY_WEIGHT*severity_mult) * crop_susceptibility
WEATHER_WEIGHT = 0.6
SEVERITY_WEIGHT = 0.4

# ══════════════════════════════════════════════════════════════════════
#  CROP  SUSCEPTIBILITY  WEIGHTS  (0.0 – 1.0)
# ══════════════════════════════════════════════════════════════════════
# Higher = more vulnerable to disease spread
# Based on: leaf surface area, growth density, physiological factors
CROP_SUSCEPTIBILITY: Dict[str, float] = {
    # High susceptibility (dense foliage, humid microclimate)
    "tomato": 1.0,
    "potato": 0.9,
    "grape": 0.85,
    "strawberry": 0.85,
    "apple": 0.8,
    "cherry": 0.8,
    "peach": 0.75,
    # Medium susceptibility
    "corn": 0.7,
    "maize": 0.7,
    "pepper": 0.65,
    "bell pepper": 0.65,
    "squash": 0.6,
    # Lower susceptibility (hardy crops)
    "orange": 0.55,
    "citrus": 0.55,
    "soybean": 0.5,
    "blueberry": 0.45,
    "raspberry": 0.45,
}
DEFAULT_SUSCEPTIBILITY = 0.6

# ══════════════════════════════════════════════════════════════════════
#  DISEASE  INTRINSIC  SEVERITY  (0.0 – 1.0)
# ══════════════════════════════════════════════════════════════════════
# Higher = more aggressive pathogen, faster spread, higher yield loss
DISEASE_SEVERITY: Dict[str, float] = {
    # Critical severity (can destroy entire crop in days)
    "Tomato___Late_blight": 1.0,
    "Potato___Late_blight": 1.0,
    "Orange___Haunglongbing_(Citrus_greening)": 0.95,
    "Tomato___Tomato_Yellow_Leaf_Curl_Virus": 0.9,
    # High severity
    "Tomato___Early_blight": 0.8,
    "Potato___Early_blight": 0.8,
    "Grape___Black_rot": 0.8,
    "Apple___Apple_scab": 0.75,
    "Corn_(maize)___Northern_Leaf_Blight": 0.75,
    "Tomato___Bacterial_spot": 0.7,
    "Tomato___Septoria_leaf_spot": 0.7,
    # Medium severity
    "Apple___Black_rot": 0.65,
    "Apple___Cedar_apple_rust": 0.6,
    "Tomato___Leaf_Mold": 0.6,
    "Tomato___Target_Spot": 0.6,
    "Corn_(maize)___Common_rust_": 0.55,
    "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot": 0.55,
    "Grape___Leaf_blight_(Isariopsis_Leaf_Spot)": 0.55,
    "Pepper,_bell___Bacterial_spot": 0.55,
    "Peach___Bacterial_spot": 0.55,
    # Lower severity (manageable with treatment)
    "Squash___Powdery_mildew": 0.45,
    "Cherry_(including_sour)___Powdery_mildew": 0.45,
    "Strawberry___Leaf_scorch": 0.5,
    "Tomato___Tomato_mosaic_virus": 0.5,
    "Tomato___Spider_mites Two-spotted_spider_mite": 0.4,
    "Grape___Esca_(Black_Measles)": 0.5,
}
DEFAULT_SEVERITY = 0.5

# ── Haversine ─────────────────────────────────────────────────────────
def _haversine(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Distance in km between two lat/lng points."""
    R = 6371
    d_lat = math.radians(lat2 - lat1)
    d_lng = math.radians(lng2 - lng1)
    a = (math.sin(d_lat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(d_lng / 2) ** 2)
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


# ══════════════════════════════════════════════════════════════════════
#  DISEASE  COMMUNICABILITY  KNOWLEDGE  BASE
# ══════════════════════════════════════════════════════════════════════
_DISEASE_SPREAD_DB: Dict[str, dict] = {
    # ── Apple ─────────────────────────────────────────────────────────
    "Apple___Apple_scab": {
        "communicable": True,
        "vector": "airborne",
        "spread_desc": "Spores spread by wind and rain splash. Highly contagious in wet seasons.",
        "weather_triggers": {"high_humidity": True, "rain": True, "temp_range": [15, 25]},
        "crop_family": "Apple",
    },
    "Apple___Black_rot": {
        "communicable": True,
        "vector": "airborne",
        "spread_desc": "Fungal spores spread by wind and rain. Cankers on branches are persistent infection sources.",
        "weather_triggers": {"high_humidity": True, "rain": True, "temp_range": [20, 30]},
        "crop_family": "Apple",
    },
    "Apple___Cedar_apple_rust": {
        "communicable": True,
        "vector": "airborne",
        "spread_desc": "Wind-borne spores travel kilometers from junipers/cedars to apple trees.",
        "weather_triggers": {"high_humidity": True, "rain": True, "temp_range": [10, 25]},
        "crop_family": "Apple",
    },
    "Apple___healthy": {"communicable": False, "vector": "none", "spread_desc": "Healthy plant.", "weather_triggers": {}, "crop_family": "Apple"},

    # ── Tomato ────────────────────────────────────────────────────────
    "Tomato___Early_blight": {
        "communicable": True,
        "vector": "airborne",
        "spread_desc": "Alternaria spores disperse via wind and splashing water. Survives in soil debris.",
        "weather_triggers": {"high_humidity": True, "rain": True, "temp_range": [24, 30]},
        "crop_family": "Tomato",
    },
    "Tomato___Late_blight": {
        "communicable": True,
        "vector": "airborne",
        "spread_desc": "Phytophthora infestans spores travel long distances by wind. Extremely contagious in cool wet conditions.",
        "weather_triggers": {"high_humidity": True, "rain": True, "temp_range": [12, 22]},
        "crop_family": "Tomato",
    },
    "Tomato___Bacterial_spot": {
        "communicable": True,
        "vector": "waterborne",
        "spread_desc": "Bacteria spread by rain splash, overhead irrigation, and contaminated tools.",
        "weather_triggers": {"high_humidity": True, "rain": True, "temp_range": [22, 35]},
        "crop_family": "Tomato",
    },
    "Tomato___Leaf_Mold": {
        "communicable": True,
        "vector": "airborne",
        "spread_desc": "Spores spread by air movement, especially in humid enclosed environments.",
        "weather_triggers": {"high_humidity": True, "rain": False, "temp_range": [20, 28]},
        "crop_family": "Tomato",
    },
    "Tomato___Septoria_leaf_spot": {
        "communicable": True,
        "vector": "waterborne",
        "spread_desc": "Rain splash spreads spores from infected debris to healthy plants.",
        "weather_triggers": {"high_humidity": True, "rain": True, "temp_range": [20, 28]},
        "crop_family": "Tomato",
    },
    "Tomato___Target_Spot": {
        "communicable": True,
        "vector": "airborne",
        "spread_desc": "Corynespora spores disperse via wind and rain.",
        "weather_triggers": {"high_humidity": True, "rain": True, "temp_range": [25, 32]},
        "crop_family": "Tomato",
    },
    "Tomato___Tomato_Yellow_Leaf_Curl_Virus": {
        "communicable": True,
        "vector": "insect",
        "spread_desc": "Spread by whiteflies (Bemisia tabaci). Infected plants are permanent virus reservoirs.",
        "weather_triggers": {"high_humidity": False, "rain": False, "temp_range": [25, 35]},
        "crop_family": "Tomato",
    },
    "Tomato___Tomato_mosaic_virus": {
        "communicable": True,
        "vector": "contact",
        "spread_desc": "Transmitted by physical contact — tools, hands, transplanting. Extremely stable virus.",
        "weather_triggers": {"high_humidity": False, "rain": False, "temp_range": [15, 35]},
        "crop_family": "Tomato",
    },
    "Tomato___Spider_mites Two-spotted_spider_mite": {
        "communicable": True,
        "vector": "wind",
        "spread_desc": "Spider mites disperse via wind and can colonize nearby fields rapidly.",
        "weather_triggers": {"high_humidity": False, "rain": False, "temp_range": [25, 35]},
        "crop_family": "Tomato",
    },
    "Tomato___healthy": {"communicable": False, "vector": "none", "spread_desc": "Healthy plant.", "weather_triggers": {}, "crop_family": "Tomato"},

    # ── Potato ────────────────────────────────────────────────────────
    "Potato___Early_blight": {
        "communicable": True,
        "vector": "airborne",
        "spread_desc": "Alternaria spores spread by wind and rain splash from infected debris.",
        "weather_triggers": {"high_humidity": True, "rain": True, "temp_range": [24, 30]},
        "crop_family": "Potato",
    },
    "Potato___Late_blight": {
        "communicable": True,
        "vector": "airborne",
        "spread_desc": "Same pathogen as Tomato Late Blight. Spores travel kilometers by wind. Can cross-infect tomato and potato.",
        "weather_triggers": {"high_humidity": True, "rain": True, "temp_range": [12, 22]},
        "crop_family": "Potato",
    },
    "Potato___healthy": {"communicable": False, "vector": "none", "spread_desc": "Healthy plant.", "weather_triggers": {}, "crop_family": "Potato"},

    # ── Corn / Maize ──────────────────────────────────────────────────
    "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot": {
        "communicable": True,
        "vector": "airborne",
        "spread_desc": "Spores disperse by wind from residue. Thrives in prolonged dew periods.",
        "weather_triggers": {"high_humidity": True, "rain": True, "temp_range": [22, 32]},
        "crop_family": "Corn",
    },
    "Corn_(maize)___Common_rust_": {
        "communicable": True,
        "vector": "airborne",
        "spread_desc": "Rust spores are wind-borne over vast distances; no local overwintering required.",
        "weather_triggers": {"high_humidity": True, "rain": False, "temp_range": [16, 25]},
        "crop_family": "Corn",
    },
    "Corn_(maize)___Northern_Leaf_Blight": {
        "communicable": True,
        "vector": "airborne",
        "spread_desc": "Spores released from infected residue, dispersed by wind and rain.",
        "weather_triggers": {"high_humidity": True, "rain": True, "temp_range": [18, 27]},
        "crop_family": "Corn",
    },
    "Corn_(maize)___healthy": {"communicable": False, "vector": "none", "spread_desc": "Healthy plant.", "weather_triggers": {}, "crop_family": "Corn"},

    # ── Grape ─────────────────────────────────────────────────────────
    "Grape___Black_rot": {
        "communicable": True,
        "vector": "waterborne",
        "spread_desc": "Fungal spores spread by rain splash. Mummified berries are primary inoculum.",
        "weather_triggers": {"high_humidity": True, "rain": True, "temp_range": [20, 30]},
        "crop_family": "Grape",
    },
    "Grape___Esca_(Black_Measles)": {
        "communicable": False,
        "vector": "wound",
        "spread_desc": "Trunk disease enters through pruning wounds. Not directly communicable field-to-field.",
        "weather_triggers": {"high_humidity": False, "rain": False, "temp_range": [20, 35]},
        "crop_family": "Grape",
    },
    "Grape___Leaf_blight_(Isariopsis_Leaf_Spot)": {
        "communicable": True,
        "vector": "airborne",
        "spread_desc": "Spores spread by wind and rain in warm humid conditions.",
        "weather_triggers": {"high_humidity": True, "rain": True, "temp_range": [22, 30]},
        "crop_family": "Grape",
    },
    "Grape___healthy": {"communicable": False, "vector": "none", "spread_desc": "Healthy plant.", "weather_triggers": {}, "crop_family": "Grape"},

    # ── Pepper ────────────────────────────────────────────────────────
    "Pepper,_bell___Bacterial_spot": {
        "communicable": True,
        "vector": "waterborne",
        "spread_desc": "Bacteria spread by rain splash and contaminated tools. Can spread to nearby pepper fields.",
        "weather_triggers": {"high_humidity": True, "rain": True, "temp_range": [22, 35]},
        "crop_family": "Pepper",
    },
    "Pepper,_bell___healthy": {"communicable": False, "vector": "none", "spread_desc": "Healthy plant.", "weather_triggers": {}, "crop_family": "Pepper"},

    # ── Peach ─────────────────────────────────────────────────────────
    "Peach___Bacterial_spot": {
        "communicable": True,
        "vector": "waterborne",
        "spread_desc": "Bacteria spread by wind-driven rain. Warm, wet weather accelerates outbreaks.",
        "weather_triggers": {"high_humidity": True, "rain": True, "temp_range": [20, 30]},
        "crop_family": "Peach",
    },
    "Peach___healthy": {"communicable": False, "vector": "none", "spread_desc": "Healthy plant.", "weather_triggers": {}, "crop_family": "Peach"},

    # ── Cherry ────────────────────────────────────────────────────────
    "Cherry_(including_sour)___Powdery_mildew": {
        "communicable": True,
        "vector": "airborne",
        "spread_desc": "Spores disperse by wind. Does not need rain — dry, warm conditions favor it.",
        "weather_triggers": {"high_humidity": True, "rain": False, "temp_range": [18, 28]},
        "crop_family": "Cherry",
    },
    "Cherry_(including_sour)___healthy": {"communicable": False, "vector": "none", "spread_desc": "Healthy plant.", "weather_triggers": {}, "crop_family": "Cherry"},

    # ── Strawberry ────────────────────────────────────────────────────
    "Strawberry___Leaf_scorch": {
        "communicable": True,
        "vector": "waterborne",
        "spread_desc": "Spores spread by rain splash. Crowded planting increases risk.",
        "weather_triggers": {"high_humidity": True, "rain": True, "temp_range": [22, 30]},
        "crop_family": "Strawberry",
    },
    "Strawberry___healthy": {"communicable": False, "vector": "none", "spread_desc": "Healthy plant.", "weather_triggers": {}, "crop_family": "Strawberry"},

    # ── Squash ────────────────────────────────────────────────────────
    "Squash___Powdery_mildew": {
        "communicable": True,
        "vector": "airborne",
        "spread_desc": "Wind-dispersed spores infect new leaves rapidly. Does not require rain.",
        "weather_triggers": {"high_humidity": True, "rain": False, "temp_range": [20, 30]},
        "crop_family": "Squash",
    },

    # ── Orange ────────────────────────────────────────────────────────
    "Orange___Haunglongbing_(Citrus_greening)": {
        "communicable": True,
        "vector": "insect",
        "spread_desc": "Spread by Asian citrus psyllid. Once established, infected trees must be removed to prevent spread.",
        "weather_triggers": {"high_humidity": False, "rain": False, "temp_range": [20, 35]},
        "crop_family": "Orange",
    },

    # ── Single-class healthy crops ────────────────────────────────────
    "Blueberry___healthy": {"communicable": False, "vector": "none", "spread_desc": "Healthy plant.", "weather_triggers": {}, "crop_family": "Blueberry"},
    "Raspberry___healthy": {"communicable": False, "vector": "none", "spread_desc": "Healthy plant.", "weather_triggers": {}, "crop_family": "Raspberry"},
    "Soybean___healthy": {"communicable": False, "vector": "none", "spread_desc": "Healthy plant.", "weather_triggers": {}, "crop_family": "Soybean"},
}

# Cross-infection map — diseases that can jump between related crops
_CROSS_INFECTION = {
    "Potato___Late_blight": ["Tomato"],
    "Tomato___Late_blight": ["Potato"],
    "Tomato___Early_blight": ["Potato"],
    "Potato___Early_blight": ["Tomato"],
}


# ══════════════════════════════════════════════════════════════════════
#  DATA  FETCHERS
# ══════════════════════════════════════════════════════════════════════

def _get_user_crops(user_id: str) -> List[str]:
    """Fetch user's crops from Firestore."""
    if db is None:
        return []
    try:
        doc = db.collection("users").document(user_id).get()
        if doc.exists:
            return doc.to_dict().get("crops", [])
    except Exception as e:
        print(f"[PredictionEngine] Error fetching user crops: {e}")
    return []


def _get_recent_diagnoses(
    district: Optional[str],
    village: Optional[str],
    lat: float,
    lng: float,
    radius_km: int = DEFAULT_RADIUS_KM,
    days: int = DEFAULT_LOOKBACK_DAYS,
) -> List[dict]:
    """
    Fetch recent diagnosis records near the user's location.
    Uses district/village matching first, then falls back to distance filtering.
    Each result includes '_distance_km' for distance decay weighting.
    """
    if db is None:
        return []

    cutoff = datetime.utcnow() - timedelta(days=days)
    results: List[dict] = []

    try:
        query = db.collection("diagnoses").where("createdAt", ">=", cutoff)

        for doc in query.stream():
            data = doc.to_dict()
            loc = data.get("location") or {}

            # Skip healthy diagnoses
            disease = data.get("disease", "")
            if "healthy" in disease.lower():
                continue

            # Calculate distance (default to 0 for district/village matches)
            dist_km = 0.0
            matched = False

            if "lat" in loc and "lng" in loc:
                dist_km = _haversine(lat, lng, loc["lat"], loc["lng"])
                if dist_km <= radius_km:
                    matched = True
            
            # District/village match (use small default distance for weighting)
            if not matched:
                if district and loc.get("district") and loc["district"].lower() == district.lower():
                    matched = True
                    dist_km = 5.0  # Assume ~5km for same district match
                elif village and loc.get("village") and loc["village"].lower() == village.lower():
                    matched = True
                    dist_km = 2.0  # Assume ~2km for same village match

            if matched:
                data["_doc_id"] = doc.id
                data["_distance_km"] = round(dist_km, 2)
                # Convert timestamps
                if "createdAt" in data and hasattr(data["createdAt"], "isoformat"):
                    data["createdAt"] = data["createdAt"].isoformat()
                results.append(data)

    except Exception as e:
        print(f"[PredictionEngine] Error fetching diagnoses: {e}")

    return results


def _get_community_disease_posts(
    district: Optional[str],
    village: Optional[str],
    lat: float,
    lng: float,
    radius_km: int = DEFAULT_RADIUS_KM,
    days: int = DEFAULT_LOOKBACK_DAYS,
) -> List[dict]:
    """Fetch community posts that contain disease/analysis data.
    Each result includes '_distance_km' for distance decay weighting.
    """
    if db is None:
        return []

    cutoff = datetime.utcnow() - timedelta(days=days)
    results: List[dict] = []

    try:
        query = db.collection("community").where("createdAt", ">=", cutoff)

        for doc in query.stream():
            data = doc.to_dict()
            loc = data.get("location") or {}

            # Only posts with analysis data
            if not data.get("analysisData"):
                continue

            # Calculate distance
            dist_km = 0.0
            matched = False
            
            if "lat" in loc and "lng" in loc:
                dist_km = _haversine(lat, lng, loc["lat"], loc["lng"])
                if dist_km <= radius_km:
                    matched = True
            
            # District/village match
            if not matched:
                if district and loc.get("district") and loc["district"].lower() == district.lower():
                    matched = True
                    dist_km = 5.0
                elif village and loc.get("village") and loc["village"].lower() == village.lower():
                    matched = True
                    dist_km = 2.0

            if matched:
                data["_doc_id"] = doc.id
                data["_distance_km"] = round(dist_km, 2)
                if "createdAt" in data and hasattr(data["createdAt"], "isoformat"):
                    data["createdAt"] = data["createdAt"].isoformat()
                results.append(data)

    except Exception as e:
        print(f"[PredictionEngine] Error fetching community posts: {e}")

    return results


# ══════════════════════════════════════════════════════════════════════
#  WEATHER  RISK  ANALYZER
# ══════════════════════════════════════════════════════════════════════

def _assess_weather_risk(weather: dict, disease_key: str) -> dict:
    """
    Check if current/forecasted weather conditions favor the given disease.

    Returns:
        {
            "weather_favors_spread": bool,
            "factors": [str],
            "weather_multiplier": float (0.0 – 1.0) — used in multiplicative risk formula
        }
    """
    spread_info = _DISEASE_SPREAD_DB.get(disease_key, {})
    triggers = spread_info.get("weather_triggers", {})

    if not triggers or not weather:
        return {"weather_favors_spread": False, "factors": [], "weather_multiplier": 0.0}

    factors: List[str] = []
    score = 0.0  # Accumulates 0-4 points based on conditions met

    current = weather.get("current", {})
    forecast_days = weather.get("forecast", {}).get("forecastday", [])

    # Current conditions
    humidity = current.get("humidity", 50)
    temp_c = current.get("temp_c", 25)
    condition_text = current.get("condition", {}).get("text", "").lower()

    # Check humidity (0-1.5 points based on severity)
    if triggers.get("high_humidity"):
        if humidity > 85:
            factors.append(f"Very high humidity ({humidity}%) — ideal for pathogen growth")
            score += 1.5
        elif humidity > 70:
            factors.append(f"High humidity ({humidity}%) favors pathogen growth")
            score += 1.0
        elif humidity > 60:
            score += 0.3

    # Check temperature range (0-1.5 points)
    temp_range = triggers.get("temp_range", [])
    if temp_range and len(temp_range) == 2:
        t_min, t_max = temp_range
        t_mid = (t_min + t_max) / 2
        if t_min <= temp_c <= t_max:
            # Closer to midpoint = higher score
            distance_from_mid = abs(temp_c - t_mid) / ((t_max - t_min) / 2)
            temp_score = 1.5 * (1 - distance_from_mid * 0.5)
            factors.append(f"Temperature ({temp_c}°C) is in optimal range for this pathogen ({t_min}-{t_max}°C)")
            score += temp_score

    # Check rain (0-1.5 points from forecast)
    if triggers.get("rain"):
        rain_score = 0.0
        for day_data in forecast_days[:3]:  # next 3 days
            precip = day_data.get("day", {}).get("totalprecip_mm", 0)
            if precip > 20:
                factors.append(f"Heavy rain expected ({precip}mm on {day_data.get('date', 'soon')}), aiding spore dispersal")
                rain_score = max(rain_score, 1.5)
            elif precip > 10:
                factors.append(f"Moderate rain expected ({precip}mm on {day_data.get('date', 'soon')}), aiding spore dispersal")
                rain_score = max(rain_score, 1.0)
            elif precip > 5:
                rain_score = max(rain_score, 0.5)
        score += rain_score

        # Current rainy condition (bonus 0.5)
        if any(kw in condition_text for kw in ["rain", "drizzle", "shower", "thunderstorm"]):
            factors.append("Currently raining — active spore dispersal conditions")
            score += 0.5

    # Normalize score to 0-1 multiplier (max theoretical = 5.0)
    weather_multiplier = min(score / 4.0, 1.0)
    
    favors = len(factors) > 0
    return {
        "weather_favors_spread": favors,
        "factors": factors,
        "weather_multiplier": round(weather_multiplier, 3),
    }


# ══════════════════════════════════════════════════════════════════════
#  LLM  RISK  SUMMARY  (optional enrichment)
# ══════════════════════════════════════════════════════════════════════

def _generate_llm_risk_summary(alert_data: dict) -> Optional[str]:
    """
    Use Gemini to generate a concise, farmer-friendly risk summary.
    Falls back to a template if LLM is unavailable.
    """
    gemini_api_key = _get_gemini_key()
    if not gemini_api_key:
        return _generate_local_risk_summary(alert_data)

    prompt = f"""You are a crop disease risk advisor for Indian farmers.
Given the following disease alert data, write a SHORT (3-4 sentence), clear, actionable summary in simple English.

ALERT DATA:
- Crop at risk: {alert_data.get('crop')}
- Disease detected nearby: {alert_data.get('disease_name')}
- Cases in area: {alert_data.get('case_count')}
- Nearest case: {alert_data.get('nearest_case_km', 'unknown')} km away
- Risk level: {alert_data.get('risk_level')} ({alert_data.get('risk_score', 0)*100:.0f}%)
- Crop vulnerability: {alert_data.get('risk_breakdown', {}).get('crop_susceptibility', 0.6)*100:.0f}%
- Disease severity: {alert_data.get('risk_breakdown', {}).get('disease_severity', 0.5)*100:.0f}%
- Spread vector: {alert_data.get('vector')}
- Weather conditions: {json.dumps(alert_data.get('weather_factors', []))}
- Preventive tips: {json.dumps(alert_data.get('prevention', [])[:3])}

Return ONLY the summary text, no JSON, no markdown.
"""

    payload = {"contents": [{"parts": [{"text": prompt}]}]}

    for model in GEMINI_MODELS:
        url = f"{API_BASE}/{model}:generateContent?key={gemini_api_key}"
        try:
            resp = requests.post(
                url,
                headers={"Content-Type": "application/json"},
                data=json.dumps(payload),
                timeout=30,
            )
            if resp.status_code in (403, 404, 429):
                # write debug info for failed model
                with open("gemini_debug.log", "a") as f:
                    f.write(f"\n[PredEngine] model={model} status={resp.status_code} body={resp.text}\n")
                continue
            resp.raise_for_status()
            body = None
            try:
                body = resp.json()
            except Exception:
                body = None

            # safe extraction
            text = None
            if isinstance(body, dict):
                def find_text(o):
                    if isinstance(o, dict):
                        for k, v in o.items():
                            if k == "text" and isinstance(v, str):
                                return v
                            res = find_text(v)
                            if res:
                                return res
                    if isinstance(o, list):
                        for item in o:
                            res = find_text(item)
                            if res:
                                return res
                    return None
                text = find_text(body)

            if text:
                return text.strip()
            else:
                with open("gemini_debug.log", "a") as f:
                    f.write(f"\n[PredEngine] model={model} no text found status={resp.status_code} body={resp.text}\n")
                continue
        except Exception as e:
            print(f"[PredictionEngine] LLM risk summary failed ({model}): {e}")
            with open("gemini_debug.log", "a") as f:
                f.write(f"\n[PredEngine EXC] model={model} err={e}\n")
            continue

    return _generate_local_risk_summary(alert_data)


def _generate_local_risk_summary(alert_data: dict) -> str:
    """Template-based fallback when LLM is unavailable."""
    crop = alert_data.get("crop", "your crop")
    disease = alert_data.get("disease_name", "a disease")
    cases = alert_data.get("case_count", 0)
    risk = alert_data.get("risk_level", "medium")
    vector = alert_data.get("vector", "unknown")
    weather_factors = alert_data.get("weather_factors", [])
    nearest_km = alert_data.get("nearest_case_km")
    risk_breakdown = alert_data.get("risk_breakdown", {})

    # Distance info
    dist_text = f", with the nearest case just {nearest_km}km away" if nearest_km and nearest_km < 10 else ""
    
    summary = f"{disease.replace('_', ' ')} has been detected in {cases} nearby field(s){dist_text}, posing a {risk.upper()} risk to your {crop} crop. "

    # Susceptibility warning
    susceptibility = risk_breakdown.get("crop_susceptibility", 0.6)
    if susceptibility >= 0.8:
        summary += f"Your {crop} crop is highly susceptible to this disease. "

    if vector == "airborne":
        summary += "Wind-carried spores can reach your field easily. "
    elif vector == "waterborne":
        summary += "Rain splash and irrigation can spread this pathogen. "
    elif vector == "insect":
        summary += "Insect vectors actively spread this disease. "
    elif vector == "contact":
        summary += "Contaminated tools and physical contact spread this pathogen. "

    if weather_factors:
        summary += f"Current weather ({', '.join(weather_factors[:2])}) accelerates spread. "

    summary += "Take preventive action immediately."
    return summary


# ══════════════════════════════════════════════════════════════════════
#  MAIN  ENGINE  —  generate_alerts()
# ══════════════════════════════════════════════════════════════════════

# Local knowledge base for prevention (from llm.py _DISEASE_DB)
from doc_feature.llm import _DISEASE_DB


def generate_alerts(
    user_id: str,
    lat: float,
    lng: float,
    district: Optional[str] = None,
    village: Optional[str] = None,
    user_crops: Optional[List[str]] = None,
) -> dict:
    """
    Main entry point — produce predictive disease alerts for a user.

    Args:
        user_id: Phone number
        lat, lng: User's current location
        district, village: Optional pre-resolved location strings
        user_crops: Optional crop list (fetched from DB if not provided)

    Returns:
        {
            "alerts": [...],
            "summary": {"total_alerts": int, "high_risk": int, ...},
            "weather": {...},
            "generated_at": str
        }
    """
    # 1. Resolve user crops
    crops = user_crops or _get_user_crops(user_id)
    if not crops:
        return {
            "alerts": [],
            "summary": {"total_alerts": 0, "high_risk": 0, "medium_risk": 0, "low_risk": 0},
            "weather": None,
            "generated_at": datetime.utcnow().isoformat(),
            "message": "No crops registered. Add crops in your profile to receive alerts.",
        }

    # Normalize crop names for matching (capitalize first letter)
    crops_normalized = [c.strip().capitalize() for c in crops]

    # 2. Fetch weather
    weather = get_weather_forecast(lat, lng, days=3)

    # 3. Fetch nearby diagnoses
    diagnoses = _get_recent_diagnoses(district, village, lat, lng)

    # 4. Fetch community posts with disease data
    community_posts = _get_community_disease_posts(district, village, lat, lng)

    # 5. Build disease occurrence map: { disease_key: [records] }
    disease_occurrences: Dict[str, List[dict]] = {}

    for diag in diagnoses:
        disease_key = diag.get("disease", "")
        if disease_key and "healthy" not in disease_key.lower():
            disease_occurrences.setdefault(disease_key, []).append({
                "source": "diagnosis",
                "crop": diag.get("crop", ""),
                "confidence": diag.get("confidence", 0),
                "location": diag.get("location", {}),
                "created_at": diag.get("createdAt", ""),
                "distance_km": diag.get("_distance_km", 10.0),  # Include distance for decay
                "llm": diag.get("llm", {}),
            })

    for post in community_posts:
        analysis = post.get("analysisData", {})
        disease_key = analysis.get("disease") or analysis.get("predicted_disease", "")
        if disease_key and "healthy" not in disease_key.lower():
            disease_occurrences.setdefault(disease_key, []).append({
                "source": "community",
                "crop": analysis.get("crop", ""),
                "confidence": analysis.get("confidence", 0),
                "location": post.get("location", {}),
                "created_at": post.get("createdAt", ""),
                "distance_km": post.get("_distance_km", 10.0),  # Include distance for decay
            })

    # 6. Generate alerts for each user crop
    alerts: List[dict] = []

    for crop in crops_normalized:
        crop_lower = crop.lower()

        for disease_key, occurrences in disease_occurrences.items():
            spread_info = _DISEASE_SPREAD_DB.get(disease_key, {})

            # Skip non-communicable diseases (no risk of spread)
            if not spread_info.get("communicable", False):
                continue

            # Check if this disease affects the user's crop
            disease_crop_family = spread_info.get("crop_family", "").lower()
            disease_crop_from_key = disease_key.split("___")[0].replace("_", " ").replace(",", "").lower()

            # Direct match
            affects_user_crop = (
                crop_lower == disease_crop_family.lower()
                or crop_lower in disease_crop_from_key
                or disease_crop_from_key in crop_lower
            )

            # Cross-infection check (e.g., Potato Late Blight → Tomato)
            cross_infection_crops = _CROSS_INFECTION.get(disease_key, [])
            if not affects_user_crop and crop in cross_infection_crops:
                affects_user_crop = True

            if not affects_user_crop:
                continue

            # This disease is relevant to this user crop
            case_count = len(occurrences)
            if case_count < MIN_CASES_FOR_ALERT:
                continue

            # ══════════════════════════════════════════════════════════════
            #  ENHANCED RISK CALCULATION — Multiplicative Model
            # ══════════════════════════════════════════════════════════════
            
            # 1. Distance-weighted case aggregation (epidemiology formula)
            # weight = e^(-distance / DECAY_CONSTANT)
            # Closer cases contribute more to risk
            weighted_case_score = 0.0
            min_distance = float('inf')
            
            for occ in occurrences:
                dist = occ.get("distance_km", 10.0)
                min_distance = min(min_distance, dist)
                # Exponential decay: e^(-d/10)
                weight = math.exp(-dist / DISTANCE_DECAY_CONSTANT)
                weighted_case_score += weight
            
            # Normalize weighted score to 0.3-0.7 range
            # 1 case at 0km = weight 1.0 → base 0.4
            # 3 cases at 5km = weight ~1.8 → base 0.55
            # 5 cases at 2km = weight ~4.1 → base 0.7
            base_risk = min(0.3 + (weighted_case_score * 0.15), 0.7)

            # 2. Get crop susceptibility (how vulnerable is this crop?)
            crop_susceptibility = CROP_SUSCEPTIBILITY.get(crop_lower, DEFAULT_SUSCEPTIBILITY)
            
            # 3. Get disease severity (how aggressive is this pathogen?)
            disease_severity = DISEASE_SEVERITY.get(disease_key, DEFAULT_SEVERITY)
            severity_multiplier = disease_severity  # Already 0-1
            
            # 4. Weather risk assessment
            weather_risk = _assess_weather_risk(weather, disease_key)
            weather_multiplier = weather_risk["weather_multiplier"]
            
            # 5. MULTIPLICATIVE RISK FORMULA
            # risk = base * (1 + w1*weather + w2*severity) * crop_susceptibility
            # This amplifies risk when conditions align, rather than just adding
            amplification_factor = 1 + (WEATHER_WEIGHT * weather_multiplier) + (SEVERITY_WEIGHT * severity_multiplier)
            total_risk = base_risk * amplification_factor * crop_susceptibility
            total_risk = min(total_risk, 1.0)  # Cap at 1.0

            # Determine risk level
            if total_risk >= HIGH_RISK_THRESHOLD:
                risk_level = "high"
            elif total_risk >= MEDIUM_RISK_THRESHOLD:
                risk_level = "medium"
            else:
                risk_level = "low"

            # Get prevention tips from _DISEASE_DB
            disease_info = _DISEASE_DB.get(disease_key, {})
            prevention = disease_info.get("prevention", [
                "Monitor your crops daily",
                "Consult local agricultural officer",
            ])

            # Readable disease name
            disease_name = disease_key.split("___")[-1].replace("_", " ").strip()

            alert_data = {
                "crop": crop,
                "disease_key": disease_key,
                "disease_name": disease_name,
                "case_count": case_count,
                "nearest_case_km": round(min_distance, 1) if min_distance != float('inf') else None,
                "weighted_score": round(weighted_case_score, 2),
                "risk_score": round(total_risk, 2),
                "risk_level": risk_level,
                # Risk breakdown (for transparency)
                "risk_breakdown": {
                    "base_risk": round(base_risk, 3),
                    "crop_susceptibility": round(crop_susceptibility, 2),
                    "disease_severity": round(disease_severity, 2),
                    "weather_multiplier": round(weather_multiplier, 2),
                    "amplification_factor": round(amplification_factor, 2),
                },
                "communicable": True,
                "vector": spread_info.get("vector", "unknown"),
                "spread_description": spread_info.get("spread_desc", ""),
                "weather_favors_spread": weather_risk["weather_favors_spread"],
                "weather_factors": weather_risk["factors"],
                "prevention": prevention,
                "chemical_treatments": disease_info.get("chemical", []),
                "organic_treatments": disease_info.get("organic", []),
            }

            # LLM summary (best-effort, non-blocking)
            try:
                llm_summary = _generate_llm_risk_summary(alert_data)
                alert_data["ai_summary"] = llm_summary
            except Exception as e:
                print(f"[PredictionEngine] LLM summary skipped: {e}")
                alert_data["ai_summary"] = _generate_local_risk_summary(alert_data)

            alerts.append(alert_data)

    # Sort by risk score (highest first)
    alerts.sort(key=lambda a: a["risk_score"], reverse=True)

    # Summary stats
    high_count = sum(1 for a in alerts if a["risk_level"] == "high")
    medium_count = sum(1 for a in alerts if a["risk_level"] == "medium")
    low_count = sum(1 for a in alerts if a["risk_level"] == "low")

    # Build weather summary for frontend
    weather_summary = None
    if weather:
        current = weather.get("current", {})
        location_info = weather.get("location", {})
        weather_summary = {
            "temp_c": current.get("temp_c"),
            "humidity": current.get("humidity"),
            "condition": current.get("condition", {}).get("text"),
            "icon": current.get("condition", {}).get("icon"),
            "location_name": location_info.get("name"),
        }

    return {
        "alerts": alerts,
        "summary": {
            "total_alerts": len(alerts),
            "high_risk": high_count,
            "medium_risk": medium_count,
            "low_risk": low_count,
        },
        "weather": weather_summary,
        "crops_monitored": crops_normalized,
        "generated_at": datetime.utcnow().isoformat(),
    }
