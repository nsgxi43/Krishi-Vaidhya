# kvb/calendar/scheduler.py
"""
Intelligent rescheduling logic based on weather conditions.
"""

from datetime import datetime, timedelta
from .weather_service import get_weather_forecast, analyze_weather_conditions, check_activity_feasibility


def evaluate_calendar_for_rescheduling(calendar: dict) -> dict:
    """
    Evaluate a calendar and determine if any activities need rescheduling.
    
    Args:
        calendar: Calendar dict
    
    Returns:
        Rescheduling recommendations
    """
    location = calendar["location"]
    optimal_conditions = calendar["optimalConditions"]
    
    # Get 7-day weather forecast
    forecast = get_weather_forecast(location["lat"], location["lng"], days=7)
    
    if not forecast:
        return {
            "needsRescheduling": False,
            "reason": "Weather data unavailable",
            "recommendations": []
        }
    
    # Analyze weather conditions
    adverse_events = analyze_weather_conditions(forecast, optimal_conditions)
    
    recommendations = []
    
    # Check each pending activity in the next 7 days
    today = datetime.now()
    cutoff_date = today + timedelta(days=7)
    
    for activity in calendar["lifecycle"]:
        if activity["status"] != "pending":
            continue
        
        activity_date = datetime.strptime(activity["scheduledDate"], "%Y-%m-%d")
        
        if today <= activity_date <= cutoff_date:
            # Check if this activity is feasible given weather
            feasibility = check_activity_feasibility(activity, forecast, optimal_conditions)
            
            if not feasibility["feasible"]:
                recommendations.append({
                    "activity": activity["name"],
                    "currentDate": activity["scheduledDate"],
                    "reason": feasibility["reason"],
                    "action": feasibility["recommendation"],
                    "suggestedDelayDays": feasibility.get("suggested_delay_days", 0)
                })
    
    return {
        "needsRescheduling": len(recommendations) > 0,
        "adverseWeatherEvents": adverse_events,
        "recommendations": recommendations,
        "forecastCheckedAt": datetime.utcnow().isoformat()
    }


def apply_rescheduling(calendar: dict, recommendations: list) -> dict:
    """
    Apply rescheduling recommendations to a calendar.
    
    Args:
        calendar: Calendar dict
        recommendations: List of rescheduling recommendations
    
    Returns:
        Updated calendar with rescheduled activities
    """
    changes = []
    
    for rec in recommendations:
        activity_name = rec["activity"]
        delay_days = rec["suggestedDelayDays"]
        
        # Find the activity
        for activity in calendar["lifecycle"]:
            if activity["name"] == activity_name:
                old_date = activity["scheduledDate"]
                
                # Calculate new date
                current_date = datetime.strptime(old_date, "%Y-%m-%d")
                new_date = current_date + timedelta(days=delay_days)
                new_date_str = new_date.strftime("%Y-%m-%d")
                
                # Update activity
                activity["scheduledDate"] = new_date_str
                activity["status"] = "rescheduled"
                activity["rescheduledAt"] = datetime.utcnow().isoformat()
                activity["reschedulingReason"] = rec["reason"]
                
                # Track change
                changes.append({
                    "activity": activity_name,
                    "oldDate": old_date,
                    "newDate": new_date_str,
                    "reason": rec["reason"]
                })
                
                break
    
    # Add to rescheduling history
    if changes:
        history_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "changes": changes,
            "reason": "Automatic weather-based rescheduling"
        }
        calendar["reschedulingHistory"].append(history_entry)
    
    return calendar


def auto_reschedule_calendar(calendar: dict) -> dict:
    """
    Automatically evaluate and reschedule a calendar based on weather.
    
    Args:
        calendar: Calendar dict
    
    Returns:
        Updated calendar (if rescheduling was needed)
    """
    # Evaluate for rescheduling
    evaluation = evaluate_calendar_for_rescheduling(calendar)
    
    if evaluation["needsRescheduling"]:
        # Apply recommendations
        calendar = apply_rescheduling(calendar, evaluation["recommendations"])
        
        print(f"✅ Rescheduled {len(evaluation['recommendations'])} activities")
        for change in evaluation["recommendations"]:
            print(f"   - {change['activity']}: {change['reason']}")
    else:
        print(f"✅ No rescheduling needed. Weather conditions are suitable.")
    
    return calendar, evaluation