# kvb/calendar/reminder_service.py
"""
Complete notification service supporting:
1. In-App Notifications (Firestore)
2. Push Notifications (Firebase Cloud Messaging HTTP v1 API)
"""

import os
from datetime import datetime, timedelta
from typing import List, Dict
import logging
from google.oauth2 import service_account
from google.auth.transport.requests import Request
import requests

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Firebase project details
FIREBASE_PROJECT_ID = "krishivaidhya"
FCM_ENDPOINT = f"https://fcm.googleapis.com/v1/projects/{FIREBASE_PROJECT_ID}/messages:send"
SERVICE_ACCOUNT_FILE = "firebase_notification.json"  # Path to your service account JSON


def get_access_token():
    """
    Get OAuth 2.0 access token using service account.
    Required for FCM HTTP v1 API.
    
    Returns:
        Access token string
    """
    try:
        # Path to service account JSON - updated to look in kvb root directory
        service_account_path = os.path.join(
            os.path.dirname(__file__),  # calendar directory
            "..",                        # up to kvb directory
            "firebase_notification.json" # file in kvb directory
        )
        
        # Resolve to absolute path
        service_account_path = os.path.abspath(service_account_path)
        
        if not os.path.exists(service_account_path):
            logger.error(f"❌ Service account file not found at: {service_account_path}")
            logger.info(f"💡 Please ensure firebase_notification.json is in: /Users/nishanthsgowda/SE/kvb/")
            return None
        
        # Load credentials
        credentials = service_account.Credentials.from_service_account_file(
            service_account_path,
            scopes=['https://www.googleapis.com/auth/firebase.messaging']
        )
        
        # Get access token
        credentials.refresh(Request())
        
        return credentials.token
    
    except Exception as e:
        logger.error(f"❌ Failed to get access token: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return None


class ReminderType:
    """Reminder type constants."""
    THREE_DAYS_BEFORE = "3_days_before"
    ONE_DAY_BEFORE = "1_day_before"
    MORNING_OF = "morning_of"
    OVERDUE = "overdue"


def generate_reminders(calendar: dict) -> List[Dict]:
    """
    Generate reminder schedule for all pending activities.
    
    Args:
        calendar: Calendar dict
    
    Returns:
        List of reminder objects with timing and content
    """
    reminders = []
    today = datetime.now().date()
    
    for activity in calendar["lifecycle"]:
        if activity["status"] not in ["pending", "rescheduled"]:
            continue
        
        activity_date = datetime.strptime(activity["scheduledDate"], "%Y-%m-%d").date()
        days_until = (activity_date - today).days
        
        # Skip if activity is too far in the future (> 30 days)
        if days_until > 30:
            continue
        
        # 3 days before reminder
        if days_until >= 3:
            reminders.append({
                "activityName": activity["name"],
                "activityDate": activity["scheduledDate"],
                "activityCategory": activity["category"],
                "activityDescription": activity["description"],
                "activitySource": activity.get("source", "Standard practice"),
                "reminderType": ReminderType.THREE_DAYS_BEFORE,
                "reminderDate": (activity_date - timedelta(days=3)).isoformat(),
                "daysUntil": 3,
                "priority": "medium"
            })
        
        # 1 day before reminder
        if days_until >= 1:
            reminders.append({
                "activityName": activity["name"],
                "activityDate": activity["scheduledDate"],
                "activityCategory": activity["category"],
                "activityDescription": activity["description"],
                "activitySource": activity.get("source", "Standard practice"),
                "reminderType": ReminderType.ONE_DAY_BEFORE,
                "reminderDate": (activity_date - timedelta(days=1)).isoformat(),
                "daysUntil": 1,
                "priority": "high"
            })
        
        # Morning of reminder
        if days_until == 0:
            reminders.append({
                "activityName": activity["name"],
                "activityDate": activity["scheduledDate"],
                "activityCategory": activity["category"],
                "activityDescription": activity["description"],
                "activitySource": activity.get("source", "Standard practice"),
                "reminderType": ReminderType.MORNING_OF,
                "reminderDate": activity_date.isoformat(),
                "daysUntil": 0,
                "priority": "urgent"
            })
        
        # Overdue reminder
        if days_until < 0:
            reminders.append({
                "activityName": activity["name"],
                "activityDate": activity["scheduledDate"],
                "activityCategory": activity["category"],
                "activityDescription": activity["description"],
                "activitySource": activity.get("source", "Standard practice"),
                "reminderType": ReminderType.OVERDUE,
                "reminderDate": today.isoformat(),
                "daysOverdue": abs(days_until),
                "priority": "urgent"
            })
    
    return reminders


def get_todays_reminders(calendar: dict) -> List[Dict]:
    """
    Get reminders that should be sent today.
    
    Args:
        calendar: Calendar dict
    
    Returns:
        List of reminders to send today
    """
    all_reminders = generate_reminders(calendar)
    today = datetime.now().date().isoformat()
    
    todays_reminders = [r for r in all_reminders if r["reminderDate"] == today]
    
    return todays_reminders


def create_notification_message(reminder: dict, crop: str) -> dict:
    """
    Create formatted notification message.
    
    Args:
        reminder: Reminder dict
        crop: Crop name
    
    Returns:
        Formatted notification message
    """
    activity_name = reminder["activityName"]
    activity_desc = reminder["activityDescription"]
    activity_source = reminder["activitySource"]
    
    if reminder["reminderType"] == ReminderType.THREE_DAYS_BEFORE:
        return {
            "title": f"🔔 Upcoming: {activity_name}",
            "body": f"In 3 days for {crop}: {activity_desc[:100]}",
            "icon": "🔔",
            "actionText": "View Calendar",
            "actionUrl": f"/calendar/{reminder['activityDate']}"
        }
    
    elif reminder["reminderType"] == ReminderType.ONE_DAY_BEFORE:
        return {
            "title": f"⏰ Tomorrow: {activity_name}",
            "body": f"{crop}: {activity_desc[:100]}\n\nSource: {activity_source}",
            "icon": "⏰",
            "actionText": "Check Weather",
            "actionUrl": f"/weather"
        }
    
    elif reminder["reminderType"] == ReminderType.MORNING_OF:
        return {
            "title": f"🌱 Today: {activity_name}",
            "body": f"{crop}: {activity_desc[:100]}\n\nCategory: {reminder['activityCategory']}",
            "icon": "🌱",
            "actionText": "Mark as Done",
            "actionUrl": f"/calendar/complete/{reminder['activityDate']}"
        }
    
    elif reminder["reminderType"] == ReminderType.OVERDUE:
        days_overdue = reminder.get("daysOverdue", 0)
        return {
            "title": f"⚠️ Overdue: {activity_name}",
            "body": f"{crop}: This was scheduled {days_overdue} day(s) ago. Complete soon!",
            "icon": "⚠️",
            "actionText": "Reschedule",
            "actionUrl": f"/calendar/reschedule"
        }
    
    # Default
    return {
        "title": f"📋 {activity_name}",
        "body": f"{crop}: {activity_desc[:100]}",
        "icon": "📋",
        "actionText": "View",
        "actionUrl": "/calendar"
    }


def send_in_app_notification(user_id: str, reminder: dict, calendar: dict) -> bool:
    """
    Send in-app notification (store in Firestore).
    User sees this INSIDE the app when they open it.
    
    Args:
        user_id: User ID
        reminder: Reminder dict
        calendar: Calendar dict
    
    Returns:
        Success status
    """
    try:
        from ..db.firebase_init import db
        from firebase_admin import firestore
        
        # Create notification message
        message = create_notification_message(reminder, calendar["crop"])
        
        # Create notification document
        notification = {
            "userId": user_id,
            "calendarId": calendar.get("calendarId", "unknown"),
            "crop": calendar["crop"],
            "activityName": reminder["activityName"],
            "activityDate": reminder["activityDate"],
            "activityCategory": reminder["activityCategory"],
            "reminderType": reminder["reminderType"],
            "priority": reminder["priority"],
            "title": message["title"],
            "body": message["body"],
            "icon": message["icon"],
            "actionText": message["actionText"],
            "actionUrl": message["actionUrl"],
            "read": False,
            "createdAt": firestore.SERVER_TIMESTAMP,
            "type": "calendar_reminder"
        }
        
        # Save to Firestore
        db.collection("notifications").add(notification)
        
        logger.info(f"✅ In-app notification sent to user {user_id}: {message['title']}")
        return True
    
    except Exception as e:
        logger.error(f"❌ Failed to send in-app notification: {e}")
        return False


def send_push_notification(user_id: str, reminder: dict, calendar: dict) -> bool:
    """
    Send push notification via Firebase Cloud Messaging HTTP v1 API.
    Uses service account authentication (OAuth 2.0).
    
    Args:
        user_id: User ID
        reminder: Reminder dict
        calendar: Calendar dict
    
    Returns:
        Success status
    """
    try:
        from ..db.firebase_init import db
        
        # Get user's FCM device token(s) from Firestore
        user_doc = db.collection("users").document(user_id).get()
        
        if not user_doc.exists:
            logger.warning(f"⚠️ User {user_id} not found")
            return False
        
        user_data = user_doc.to_dict()
        device_tokens = user_data.get("fcmTokens", [])
        
        if not device_tokens:
            logger.warning(f"⚠️ User {user_id} has no FCM device tokens registered")
            return False
        
        # Get OAuth access token
        access_token = get_access_token()
        if not access_token:
            logger.error("❌ Failed to get access token")
            return False
        
        # Create notification message
        message = create_notification_message(reminder, calendar["crop"])
        
        # Send to all user's devices
        success_count = 0
        
        for token in device_tokens:
            # FCM HTTP v1 message format
            fcm_message = {
                "message": {
                    "token": token,
                    "notification": {
                        "title": message["title"],
                        "body": message["body"]
                    },
                    "data": {
                        "calendarId": calendar.get("calendarId", "unknown"),
                        "activityDate": reminder["activityDate"],
                        "activityName": reminder["activityName"],
                        "reminderType": reminder["reminderType"],
                        "actionUrl": message["actionUrl"],
                        "priority": reminder["priority"],
                        "icon": message["icon"]
                    },
                    "android": {
                        "priority": "high",
                        "notification": {
                            "sound": "default",
                            "click_action": "FLUTTER_NOTIFICATION_CLICK"
                        }
                    },
                    "apns": {
                        "headers": {
                            "apns-priority": "10"
                        },
                        "payload": {
                            "aps": {
                                "sound": "default",
                                "badge": 1
                            }
                        }
                    }
                }
            }
            
            # Send request
            headers = {
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json"
            }
            
            response = requests.post(
                FCM_ENDPOINT,
                json=fcm_message,
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                success_count += 1
                logger.info(f"✅ Push notification sent to device: {token[:20]}...")
            else:
                error_detail = response.json()
                logger.error(f"❌ FCM request failed: {response.status_code}")
                logger.error(f"   Error: {error_detail}")
                
                # If token is invalid, remove it from user's tokens
                if "UNREGISTERED" in str(error_detail) or "INVALID_ARGUMENT" in str(error_detail):
                    logger.info(f"🗑️ Removing invalid token: {token[:20]}...")
                    remove_device_token(user_id, token)
        
        return success_count > 0
    
    except Exception as e:
        logger.error(f"❌ Failed to send push notification: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False


def process_calendar_reminders(calendar_id: str, enable_push: bool = True) -> dict:
    """
    Process all reminders for a calendar.
    Send both in-app AND push notifications.
    
    Args:
        calendar_id: Calendar document ID
        enable_push: Enable push notifications (default True)
    
    Returns:
        Summary of reminders sent
    """
    from ..db.calendar_db_service import get_calendar
    
    calendar = get_calendar(calendar_id)
    if not calendar:
        return {"error": "Calendar not found"}
    
    # Add calendar ID to calendar dict for reference
    calendar["calendarId"] = calendar_id
    
    # Get today's reminders
    todays_reminders = get_todays_reminders(calendar)
    
    if not todays_reminders:
        return {
            "calendarId": calendar_id,
            "inAppSent": 0,
            "pushSent": 0,
            "message": "No reminders due today"
        }
    
    in_app_sent = 0
    in_app_failed = 0
    push_sent = 0
    push_failed = 0
    
    for reminder in todays_reminders:
        try:
            # 1. Send in-app notification (always)
            if send_in_app_notification(calendar["userId"], reminder, calendar):
                in_app_sent += 1
            else:
                in_app_failed += 1
            
            # 2. Send push notification (if enabled)
            if enable_push:
                if send_push_notification(calendar["userId"], reminder, calendar):
                    push_sent += 1
                else:
                    push_failed += 1
        
        except Exception as e:
            logger.error(f"Failed to send reminder: {e}")
            in_app_failed += 1
            if enable_push:
                push_failed += 1
    
    return {
        "calendarId": calendar_id,
        "crop": calendar["crop"],
        "userId": calendar["userId"],
        "inAppSent": in_app_sent,
        "inAppFailed": in_app_failed,
        "pushSent": push_sent,
        "pushFailed": push_failed,
        "totalReminders": len(todays_reminders)
    }


def get_user_notifications(user_id: str, unread_only: bool = True, limit: int = 50) -> List[Dict]:
    """
    Get in-app notifications for a user from Firestore.
    
    Args:
        user_id: User ID
        unread_only: Only return unread notifications
        limit: Maximum number of notifications to return
    
    Returns:
        List of notifications
    """
    try:
        from ..db.firebase_init import db
        from firebase_admin import firestore
        
        # Query notifications
        query = db.collection("notifications").where(
            filter=firestore.FieldFilter("userId", "==", user_id)
        )
        
        if unread_only:
            query = query.where(filter=firestore.FieldFilter("read", "==", False))
        
        # Fetch and sort
        notifications = []
        for doc in query.stream():
            notification = doc.to_dict()
            notification["notificationId"] = doc.id
            notifications.append(notification)
        
        # Sort by createdAt (newest first)
        notifications.sort(
            key=lambda x: x.get("createdAt", datetime.min), 
            reverse=True
        )
        
        return notifications[:limit]
    
    except Exception as e:
        logger.error(f"Failed to get notifications: {e}")
        return []


def mark_notification_as_read(notification_id: str) -> bool:
    """
    Mark a notification as read.
    
    Args:
        notification_id: Notification document ID
    
    Returns:
        Success status
    """
    try:
        from ..db.firebase_init import db
        from firebase_admin import firestore
        
        db.collection("notifications").document(notification_id).update({
            "read": True,
            "readAt": firestore.SERVER_TIMESTAMP
        })
        
        logger.info(f"✅ Marked notification {notification_id} as read")
        return True
    
    except Exception as e:
        logger.error(f"❌ Failed to mark notification as read: {e}")
        return False


def register_device_token(user_id: str, fcm_token: str) -> bool:
    """
    Register a user's FCM device token for push notifications.
    Call this when user opens your mobile app.
    
    Args:
        user_id: User ID (phone number)
        fcm_token: FCM device token from mobile app
    
    Returns:
        Success status
    """
    try:
        from ..db.firebase_init import db
        from firebase_admin import firestore
        
        user_ref = db.collection("users").document(user_id)
        
        # Add token to user's fcmTokens array (avoiding duplicates)
        user_ref.set({
            "fcmTokens": firestore.ArrayUnion([fcm_token]),
            "lastActive": firestore.SERVER_TIMESTAMP
        }, merge=True)
        
        logger.info(f"✅ Registered FCM token for user {user_id}")
        return True
    
    except Exception as e:
        logger.error(f"❌ Failed to register device token: {e}")
        return False


def remove_device_token(user_id: str, fcm_token: str) -> bool:
    """
    Remove a user's FCM device token (e.g., when they logout or token is invalid).
    
    Args:
        user_id: User ID
        fcm_token: FCM device token to remove
    
    Returns:
        Success status
    """
    try:
        from ..db.firebase_init import db
        from firebase_admin import firestore
        
        user_ref = db.collection("users").document(user_id)
        
        user_ref.update({
            "fcmTokens": firestore.ArrayRemove([fcm_token])
        })
        
        logger.info(f"✅ Removed FCM token for user {user_id}")
        return True
    
    except Exception as e:
        logger.error(f"❌ Failed to remove device token: {e}")
        return False


def get_notification_summary(user_id: str) -> dict:
    """
    Get notification summary for a user (for badge counts).
    
    Args:
        user_id: User ID
    
    Returns:
        Summary with counts
    """
    try:
        from ..db.firebase_init import db
        from firebase_admin import firestore
        
        # Count unread
        unread_query = db.collection("notifications").where(
            filter=firestore.FieldFilter("userId", "==", user_id)
        ).where(
            filter=firestore.FieldFilter("read", "==", False)
        )
        
        unread_count = len(list(unread_query.stream()))
        
        # Count urgent
        urgent_query = db.collection("notifications").where(
            filter=firestore.FieldFilter("userId", "==", user_id)
        ).where(
            filter=firestore.FieldFilter("read", "==", False)
        ).where(
            filter=firestore.FieldFilter("priority", "==", "urgent")
        )
        
        urgent_count = len(list(urgent_query.stream()))
        
        return {
            "userId": user_id,
            "totalUnread": unread_count,
            "urgentUnread": urgent_count
        }
    
    except Exception as e:
        logger.error(f"Failed to get notification summary: {e}")
        return {
            "userId": user_id,
            "totalUnread": 0,
            "urgentUnread": 0
        }