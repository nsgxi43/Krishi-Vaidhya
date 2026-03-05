# kvb/db/calendar_db_service.py
"""
Firestore operations for calendar management.
"""

from firebase_admin import firestore
from .firebase_init import db
from datetime import datetime


def save_calendar(calendar: dict) -> str:
    """
    Save a calendar to Firestore.
    
    Args:
        calendar: Calendar dict
    
    Returns:
        Calendar ID
    """
    if db is None:
        print("Database not available. Returning mock ID.")
        return "mock_calendar_id_123"

    # Create a copy for Firestore with SERVER_TIMESTAMP
    calendar_for_db = calendar.copy()
    calendar_for_db["createdAt"] = firestore.SERVER_TIMESTAMP
    calendar_for_db["updatedAt"] = firestore.SERVER_TIMESTAMP
    
    # Save to Firestore
    ref = db.collection("calendars").document()
    ref.set(calendar_for_db)
    
    # Add ISO timestamps to the original calendar for JSON serialization
    now = datetime.utcnow()
    calendar["createdAt"] = now.isoformat()
    calendar["updatedAt"] = now.isoformat()
    
    return ref.id


def get_calendar(calendar_id: str) -> dict:
    """
    Retrieve a calendar from Firestore.
    
    Args:
        calendar_id: Calendar document ID
    
    Returns:
        Calendar dict or None if not found
    """
    if db is None:
        print("Database not available. Returning mock calendar.")
        # Return a mock calendar for testing if needed, or None
        return {
            "calendarId": calendar_id,
            "crop": "Tomato",
            "lifecycle": [],
            "status": "active",
            "userId": "mock_user",
            "sowingDate": "2023-01-01",
            "durationDays": 100,
            "location": {"lat": 0, "lng": 0},
            "optimalConditions": {},
            "reschedulingHistory": []
        }

    doc = db.collection("calendars").document(calendar_id).get()
    
    if doc.exists:
        calendar = doc.to_dict()
        calendar["calendarId"] = doc.id
        
        # Convert Firestore timestamps to ISO format for JSON serialization
        if "createdAt" in calendar and hasattr(calendar["createdAt"], "isoformat"):
            calendar["createdAt"] = calendar["createdAt"].isoformat()
        if "updatedAt" in calendar and hasattr(calendar["updatedAt"], "isoformat"):
            calendar["updatedAt"] = calendar["updatedAt"].isoformat()
        
        return calendar
    else:
        return None


def update_calendar(calendar_id: str, calendar: dict) -> bool:
    """
    Update an existing calendar.
    
    Args:
        calendar_id: Calendar document ID
        calendar: Updated calendar dict
    
    Returns:
        True if successful
    """
    if db is None:
        return True

    # Create a copy for Firestore with SERVER_TIMESTAMP
    calendar_for_db = calendar.copy()
    calendar_for_db["updatedAt"] = firestore.SERVER_TIMESTAMP
    
    db.collection("calendars").document(calendar_id).set(calendar_for_db, merge=True)
    
    # Update original with ISO timestamp for JSON serialization
    calendar["updatedAt"] = datetime.utcnow().isoformat()
    
    return True


def delete_calendar(calendar_id: str) -> bool:
    """
    Delete a calendar.
    
    Args:
        calendar_id: Calendar document ID
    
    Returns:
        True if successful
    """
    if db is None:
        return True
    db.collection("calendars").document(calendar_id).delete()
    return True


def get_user_calendars(user_id: str, status: str = None) -> list:
    """
    Get all calendars for a user.
    
    Args:
        user_id: User ID
        status: Optional status filter ("active", "completed", "archived")
    
    Returns:
        List of calendars
    """
    if db is None:
        return []

    query = db.collection("calendars").where(filter=firestore.FieldFilter("userId", "==", user_id))
    
    if status:
        query = query.where(filter=firestore.FieldFilter("status", "==", status))
    
    # Note: Ordering requires a composite index in Firestore
    # Commented out until index is created
    # query = query.order_by("createdAt", direction=firestore.Query.DESCENDING)
    
    calendars = []
    for doc in query.stream():
        calendar = doc.to_dict()
        calendar["calendarId"] = doc.id
        calendars.append(calendar)
    
    # Sort in Python instead (temporary workaround)
    calendars.sort(key=lambda x: x.get("createdAt", datetime.min), reverse=True)
    
    return calendars


def get_active_calendars() -> list:
    """
    Get all active calendars (for background processing).
    
    Returns:
        List of active calendars
    """
    if db is None:
        return []

    query = db.collection("calendars").where(filter=firestore.FieldFilter("status", "==", "active"))
    
    calendars = []
    for doc in query.stream():
        calendar = doc.to_dict()
        calendar["calendarId"] = doc.id
        calendars.append(calendar)
    
    return calendars