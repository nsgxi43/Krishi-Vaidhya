# kvb/calendar/calendar_service.py
"""
Core calendar generation and management logic.
"""

from datetime import datetime, timedelta
from .crop_data_accurate import get_crop_lifecycle, validate_crop, get_available_crops


def generate_calendar(crop: str, sowing_date: str, location: dict, user_id: str) -> dict:
    """
    Generate a complete crop calendar.
    
    Args:
        crop: Crop name (e.g., "Tomato")
        sowing_date: Sowing date in YYYY-MM-DD format
        location: Normalized location dict with lat, lng, state, district, village, geohash
        user_id: User ID
    
    Returns:
        Calendar dict with all activities scheduled
    """
    # Validate crop
    if not validate_crop(crop):
        available = get_available_crops()
        raise ValueError(f"Unknown crop: {crop}. Available crops: {', '.join(available)}")
    
    # Get crop lifecycle
    lifecycle_data = get_crop_lifecycle(crop)
    
    # Parse sowing date
    try:
        sowing_dt = datetime.strptime(sowing_date, "%Y-%m-%d")
    except ValueError:
        raise ValueError("Invalid date format. Use YYYY-MM-DD")
    
    # Generate activities
    activities = []
    for activity_template in lifecycle_data["activities"]:
        scheduled_date = sowing_dt + timedelta(days=activity_template["day"])
        
        activity = {
            "name": activity_template["name"],
            "scheduledDate": scheduled_date.strftime("%Y-%m-%d"),
            "originalDate": scheduled_date.strftime("%Y-%m-%d"),
            "description": activity_template["description"],
            "category": activity_template["category"],
            "source": activity_template.get("source", "Standard practice"),  # ✅ FIXED
            "status": "completed" if activity_template["day"] == 0 else "pending",
            "reminderSent": False,
            "dayOffset": activity_template["day"]
        }
        activities.append(activity)
    
    # Calculate expected harvest date
    harvest_date = sowing_dt + timedelta(days=lifecycle_data["duration_days"])
    
    # Build calendar
    calendar = {
        "userId": user_id,
        "crop": crop,
        "sowingDate": sowing_date,
        "expectedHarvestDate": harvest_date.strftime("%Y-%m-%d"),
        "location": location,
        "durationDays": lifecycle_data["duration_days"],
        "lifecycle": activities,
        "reschedulingHistory": [],
        "optimalConditions": lifecycle_data["optimal_conditions"],
        "status": "active",
        "dataSource": lifecycle_data.get("data_source", "Unknown"),
        "validationStatus": lifecycle_data.get("validation_status", "Unknown")
    }
    
    return calendar


def update_activity_status(calendar: dict, activity_name: str, status: str, notes: str = None) -> dict:
    """
    Update the status of a specific activity.
    
    Args:
        calendar: Calendar dict
        activity_name: Name of activity to update
        status: New status ("pending", "completed", "skipped", "rescheduled")
        notes: Optional notes
    
    Returns:
        Updated calendar dict
    """
    activity_found = False
    for activity in calendar["lifecycle"]:
        if activity["name"] == activity_name:
            activity["status"] = status
            if notes:
                activity["notes"] = notes
            activity["updatedAt"] = datetime.utcnow().isoformat()
            activity_found = True
            break
    
    if not activity_found:
        raise ValueError(f"Activity '{activity_name}' not found in calendar")
    
    return calendar


def get_upcoming_activities(calendar: dict, days_ahead: int = 7) -> list:
    """
    Get activities scheduled in the next N days.
    
    Args:
        calendar: Calendar dict
        days_ahead: Number of days to look ahead
    
    Returns:
        List of upcoming activities
    """
    today = datetime.now()
    cutoff_date = today + timedelta(days=days_ahead)
    
    upcoming = []
    for activity in calendar["lifecycle"]:
        if activity["status"] != "completed":
            activity_date = datetime.strptime(activity["scheduledDate"], "%Y-%m-%d")
            if today <= activity_date <= cutoff_date:
                days_until = (activity_date - today).days
                activity_copy = activity.copy()
                activity_copy["daysUntil"] = days_until
                upcoming.append(activity_copy)
    
    # Sort by scheduled date
    upcoming.sort(key=lambda x: x["scheduledDate"])
    
    return upcoming


def get_overdue_activities(calendar: dict) -> list:
    """
    Get activities that are overdue.
    
    Args:
        calendar: Calendar dict
    
    Returns:
        List of overdue activities
    """
    today = datetime.now()
    
    overdue = []
    for activity in calendar["lifecycle"]:
        if activity["status"] == "pending":
            activity_date = datetime.strptime(activity["scheduledDate"], "%Y-%m-%d")
            if activity_date < today:
                days_overdue = (today - activity_date).days
                activity_copy = activity.copy()
                activity_copy["daysOverdue"] = days_overdue
                overdue.append(activity_copy)
    
    # Sort by how overdue they are
    overdue.sort(key=lambda x: x["daysOverdue"], reverse=True)
    
    return overdue


def get_calendar_progress(calendar: dict) -> dict:
    """
    Calculate calendar completion progress.
    
    Args:
        calendar: Calendar dict
    
    Returns:
        Progress statistics
    """
    total_activities = len(calendar["lifecycle"])
    completed = sum(1 for a in calendar["lifecycle"] if a["status"] == "completed")
    pending = sum(1 for a in calendar["lifecycle"] if a["status"] == "pending")
    skipped = sum(1 for a in calendar["lifecycle"] if a["status"] == "skipped")
    
    progress_percent = (completed / total_activities * 100) if total_activities > 0 else 0
    
    # Calculate days into cycle
    sowing_date = datetime.strptime(calendar["sowingDate"], "%Y-%m-%d")
    today = datetime.now()
    days_elapsed = (today - sowing_date).days
    days_remaining = calendar["durationDays"] - days_elapsed
    
    return {
        "totalActivities": total_activities,
        "completed": completed,
        "pending": pending,
        "skipped": skipped,
        "progressPercent": round(progress_percent, 1),
        "daysElapsed": days_elapsed,
        "daysRemaining": max(0, days_remaining),
        "isComplete": completed == total_activities
    }