# kvb/calendar/weather_service.py
"""
Weather API integration for intelligent calendar rescheduling.
"""

import os
import requests
from datetime import datetime, timedelta
from dotenv import load_dotenv

load_dotenv()

WEATHER_API_KEY = os.getenv("WEATHER_API_KEY")
if not WEATHER_API_KEY:
    raise RuntimeError("WEATHER_API_KEY is not set")

BASE_URL = "http://api.weatherapi.com/v1"


def get_weather_forecast(lat: float, lng: float, days: int = 7) -> dict:
    """
    Get weather forecast for a location.
    
    Args:
        lat: Latitude
        lng: Longitude
        days: Number of days to forecast (1-14)
    
    Returns:
        Weather forecast data
    """
    url = f"{BASE_URL}/forecast.json"
    
    params = {
        "key": WEATHER_API_KEY,
        "q": f"{lat},{lng}",
        "days": min(days, 14),  # API supports up to 14 days
        "aqi": "no",
        "alerts": "yes"
    }
    
    try:
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"⚠️ Weather API error: {e}")
        return None


def analyze_weather_conditions(forecast: dict, optimal_conditions: dict) -> list:
    """
    Analyze weather forecast for adverse conditions.
    
    Args:
        forecast: Weather forecast data from API
        optimal_conditions: Crop's optimal weather conditions
    
    Returns:
        List of adverse weather events
    """
    if not forecast:
        return []
    
    adverse_events = []
    
    forecast_days = forecast.get("forecast", {}).get("forecastday", [])
    
    for day_data in forecast_days:
        date = day_data["date"]
        day = day_data["day"]
        
        # Check for heavy rain
        total_precip = day.get("totalprecip_mm", 0)
        if total_precip > optimal_conditions.get("rainfall_threshold_mm", 50):
            adverse_events.append({
                "date": date,
                "type": "heavy_rain",
                "severity": "high" if total_precip > 100 else "medium",
                "value": total_precip,
                "unit": "mm",
                "description": f"Heavy rainfall expected: {total_precip}mm"
            })
        
        # Check for extreme temperatures
        max_temp = day.get("maxtemp_c", 25)
        min_temp = day.get("mintemp_c", 15)
        
        temp_max_threshold = optimal_conditions.get("temp_max", 35)
        temp_min_threshold = optimal_conditions.get("temp_min", 10)
        
        if max_temp > temp_max_threshold:
            adverse_events.append({
                "date": date,
                "type": "extreme_heat",
                "severity": "high" if max_temp > temp_max_threshold + 5 else "medium",
                "value": max_temp,
                "unit": "°C",
                "description": f"Extreme heat expected: {max_temp}°C"
            })
        
        if min_temp < temp_min_threshold:
            adverse_events.append({
                "date": date,
                "type": "frost_risk",
                "severity": "high" if min_temp < 5 else "medium",
                "value": min_temp,
                "unit": "°C",
                "description": f"Frost risk: {min_temp}°C"
            })
        
        # Check for strong winds
        max_wind = day.get("maxwind_kph", 0)
        if max_wind > 40:
            adverse_events.append({
                "date": date,
                "type": "strong_wind",
                "severity": "high" if max_wind > 60 else "medium",
                "value": max_wind,
                "unit": "km/h",
                "description": f"Strong winds expected: {max_wind} km/h"
            })
        
        # Check for drought (no rain for extended period)
        if total_precip == 0:
            adverse_events.append({
                "date": date,
                "type": "no_rain",
                "severity": "low",
                "value": 0,
                "unit": "mm",
                "description": "No rainfall expected"
            })
    
    return adverse_events


def get_weather_alerts(lat: float, lng: float) -> list:
    """
    Get active weather alerts for a location.
    
    Args:
        lat: Latitude
        lng: Longitude
    
    Returns:
        List of weather alerts
    """
    forecast = get_weather_forecast(lat, lng, days=1)
    
    if not forecast:
        return []
    
    alerts = forecast.get("alerts", {}).get("alert", [])
    
    return [
        {
            "headline": alert.get("headline"),
            "severity": alert.get("severity"),
            "urgency": alert.get("urgency"),
            "description": alert.get("desc"),
            "effective": alert.get("effective"),
            "expires": alert.get("expires")
        }
        for alert in alerts
    ]


def check_activity_feasibility(activity: dict, weather_forecast: dict, optimal_conditions: dict) -> dict:
    """
    Check if an activity can be performed given weather conditions.
    
    Args:
        activity: Activity dict with scheduledDate
        weather_forecast: Weather forecast data
        optimal_conditions: Crop's optimal conditions
    
    Returns:
        Feasibility assessment
    """
    activity_date = activity["scheduledDate"]
    activity_category = activity["category"]
    
    # Find weather for that specific date
    forecast_days = weather_forecast.get("forecast", {}).get("forecastday", [])
    
    day_weather = None
    for day in forecast_days:
        if day["date"] == activity_date:
            day_weather = day["day"]
            break
    
    if not day_weather:
        return {
            "feasible": True,
            "reason": "Weather data not available",
            "recommendation": "proceed"
        }
    
    total_precip = day_weather.get("totalprecip_mm", 0)
    max_temp = day_weather.get("maxtemp_c", 25)
    
    # Rules for different activity categories
    if activity_category == "irrigation":
        if total_precip > 20:
            return {
                "feasible": False,
                "reason": f"Heavy rain expected ({total_precip}mm)",
                "recommendation": "postpone",
                "suggested_delay_days": 2
            }
    
    elif activity_category == "spraying":
        if total_precip > 5:
            return {
                "feasible": False,
                "reason": f"Rain expected ({total_precip}mm), will wash away spray",
                "recommendation": "postpone",
                "suggested_delay_days": 2
            }
        if max_temp > 35:
            return {
                "feasible": False,
                "reason": f"Extreme heat ({max_temp}°C), spray may evaporate",
                "recommendation": "postpone",
                "suggested_delay_days": 1
            }
    
    elif activity_category == "fertilization":
        if total_precip > 50:
            return {
                "feasible": False,
                "reason": f"Heavy rain ({total_precip}mm) will leach nutrients",
                "recommendation": "postpone",
                "suggested_delay_days": 2
            }
    
    elif activity_category == "harvesting":
        if total_precip > 10:
            return {
                "feasible": False,
                "reason": f"Rain expected ({total_precip}mm), fruit quality will be affected",
                "recommendation": "advance",
                "suggested_delay_days": -1
            }
    
    elif activity_category == "planting":
        if total_precip > 40:
            return {
                "feasible": False,
                "reason": f"Heavy rain ({total_precip}mm), soil too wet",
                "recommendation": "postpone",
                "suggested_delay_days": 2
            }
    
    return {
        "feasible": True,
        "reason": "Weather conditions are suitable",
        "recommendation": "proceed"
    }