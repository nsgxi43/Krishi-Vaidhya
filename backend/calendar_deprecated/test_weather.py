# kvb/calendar/test_weather.py
"""
Test weather integration and rescheduling.
"""

from datetime import datetime, timedelta
from .weather_service import get_weather_forecast, analyze_weather_conditions
from .scheduler import evaluate_calendar_for_rescheduling, auto_reschedule_calendar
from .calendar_service import generate_calendar
from ..location.location_service import normalize_location
from ..db.calendar_db_service import save_calendar, update_calendar


def test_weather_api():
    """Test Weather API connection."""
    print("=" * 60)
    print("TEST: Weather API Connection")
    print("=" * 60)
    
    # Bangalore coordinates
    lat, lng = 12.9716, 77.5946
    
    forecast = get_weather_forecast(lat, lng, days=7)
    
    if forecast:
        location_name = forecast["location"]["name"]
        print(f"\n✅ Weather data retrieved for {location_name}")
        
        # Show forecast summary
        print("\n📅 7-Day Forecast:")
        for day in forecast["forecast"]["forecastday"]:
            date = day["date"]
            max_temp = day["day"]["maxtemp_c"]
            min_temp = day["day"]["mintemp_c"]
            precip = day["day"]["totalprecip_mm"]
            condition = day["day"]["condition"]["text"]
            
            print(f"   {date}: {condition}, {min_temp}°C - {max_temp}°C, Rain: {precip}mm")
    else:
        print("❌ Failed to retrieve weather data")


def test_adverse_weather_detection():
    """Test adverse weather detection."""
    print("\n" + "=" * 60)
    print("TEST: Adverse Weather Detection")
    print("=" * 60)
    
    lat, lng = 12.9716, 77.5946
    forecast = get_weather_forecast(lat, lng, days=7)
    
    optimal_conditions = {
        "temp_min": 15,
        "temp_max": 30,
        "rainfall_threshold_mm": 50
    }
    
    adverse_events = analyze_weather_conditions(forecast, optimal_conditions)
    
    print(f"\n⚠️ Found {len(adverse_events)} adverse weather event(s):")
    for event in adverse_events:
        print(f"   - {event['date']}: {event['description']} (Severity: {event['severity']})")


def test_calendar_rescheduling():
    """Test automatic calendar rescheduling."""
    print("\n" + "=" * 60)
    print("TEST: Calendar Rescheduling")
    print("=" * 60)
    
    # Create a test calendar with activities in the next few days
    location = normalize_location(12.9716, 77.5946)
    today = datetime.now().strftime("%Y-%m-%d")
    
    calendar = generate_calendar(
        crop="Tomato",
        sowing_date=today,
        location=location,
        user_id="test_user_weather"
    )
    
    print(f"\n✅ Created calendar for {calendar['crop']}")
    
    # Evaluate for rescheduling
    evaluation = evaluate_calendar_for_rescheduling(calendar)
    
    print(f"\n📊 Rescheduling Evaluation:")
    print(f"   Needs Rescheduling: {evaluation['needsRescheduling']}")
    print(f"   Adverse Events: {len(evaluation['adverseWeatherEvents'])}")
    print(f"   Recommendations: {len(evaluation['recommendations'])}")
    
    if evaluation["recommendations"]:
        print("\n📝 Rescheduling Recommendations:")
        for rec in evaluation["recommendations"]:
            print(f"   - {rec['activity']} on {rec['currentDate']}")
            print(f"     Reason: {rec['reason']}")
            print(f"     Action: {rec['action']} by {abs(rec['suggestedDelayDays'])} day(s)")
        
        # Apply rescheduling
        calendar, eval_result = auto_reschedule_calendar(calendar)
        
        # Save updated calendar
        calendar_id = save_calendar(calendar)
        print(f"\n💾 Saved rescheduled calendar: {calendar_id}")
    else:
        print("\n✅ No rescheduling needed - weather is favorable")


if __name__ == "__main__":
    print("\n🌦️ WEATHER INTEGRATION TESTS\n")
    
    # Test 1: Weather API
    test_weather_api()
    
    # Test 2: Adverse weather detection
    test_adverse_weather_detection()
    
    # Test 3: Calendar rescheduling
    test_calendar_rescheduling()
    
    print("\n" + "=" * 60)
    print("✅ WEATHER TESTS COMPLETED")
    print("=" * 60)