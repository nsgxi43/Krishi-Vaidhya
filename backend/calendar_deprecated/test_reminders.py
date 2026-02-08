# kvb/calendar/test_reminders.py
"""
Test reminder and notification system.
"""

from datetime import datetime, timedelta
from .calendar_service import generate_calendar
from .reminder_service import (
    generate_reminders, 
    get_todays_reminders, 
    process_calendar_reminders,
    get_user_notifications,
    register_device_token,
    get_notification_summary
)
from ..location.location_service import normalize_location
from ..db.calendar_db_service import save_calendar


def test_reminder_generation():
    """Test generating reminders for a calendar."""
    print("=" * 80)
    print("TEST: Reminder Generation")
    print("=" * 80)
    
    # Create calendar starting today
    location = normalize_location(12.9716, 77.5946)
    today = datetime.now()
    
    calendar = generate_calendar(
        crop="Tomato",
        sowing_date=today.strftime("%Y-%m-%d"),
        location=location,
        user_id="farmer_reminders"
    )
    
    print(f"\n✅ Created calendar for {calendar['crop']}")
    
    # Generate all reminders
    reminders = generate_reminders(calendar)
    
    print(f"\n📊 Reminder Statistics:")
    print(f"   Total Reminders: {len(reminders)}")
    
    # Count by type
    reminder_types = {}
    priority_counts = {}
    
    for reminder in reminders:
        r_type = reminder["reminderType"]
        priority = reminder["priority"]
        reminder_types[r_type] = reminder_types.get(r_type, 0) + 1
        priority_counts[priority] = priority_counts.get(priority, 0) + 1
    
    print(f"\n📋 Reminders by Type:")
    for r_type, count in reminder_types.items():
        print(f"   - {r_type}: {count}")
    
    print(f"\n🚨 Reminders by Priority:")
    for priority, count in priority_counts.items():
        print(f"   - {priority}: {count}")
    
    # Show upcoming reminders
    print(f"\n📅 Next 5 Reminders:")
    for reminder in sorted(reminders, key=lambda x: x["reminderDate"])[:5]:
        print(f"   {reminder['reminderDate']}: {reminder['activityName']}")
        print(f"      Type: {reminder['reminderType']}")
        print(f"      Priority: {reminder['priority']}")
        print(f"      Days Until: {reminder.get('daysUntil', 'N/A')}")
        print()


def test_todays_reminders():
    """Test getting today's reminders."""
    print("\n" + "=" * 80)
    print("TEST: Today's Reminders")
    print("=" * 80)
    
    location = normalize_location(12.9716, 77.5946)
    today = datetime.now()
    
    calendar = generate_calendar(
        crop="Potato",
        sowing_date=today.strftime("%Y-%m-%d"),
        location=location,
        user_id="farmer_today"
    )
    
    # Get today's reminders
    todays_reminders = get_todays_reminders(calendar)
    
    print(f"\n📅 Reminders Due Today: {len(todays_reminders)}")
    
    if todays_reminders:
        for reminder in todays_reminders:
            print(f"\n   🔔 {reminder['activityName']}")
            print(f"      Category: {reminder['activityCategory']}")
            print(f"      Priority: {reminder['priority']}")
            print(f"      Description: {reminder['activityDescription'][:60]}...")
    else:
        print("   No reminders due today")


def test_send_notifications():
    """Test sending notifications."""
    print("\n" + "=" * 80)
    print("TEST: Send Notifications (In-App + Push)")
    print("=" * 80)
    
    location = normalize_location(12.9716, 77.5946)
    today = datetime.now()
    
    calendar = generate_calendar(
        crop="Corn",
        sowing_date=today.strftime("%Y-%m-%d"),
        location=location,
        user_id="9999999999"
    )
    
    # Save calendar
    calendar_id = save_calendar(calendar)
    print(f"\n✅ Created calendar: {calendar_id}")
    
    # Register a test FCM token for the user
    test_fcm_token = "test_device_token_12345_for_testing"
    register_device_token("9999999999", test_fcm_token)
    print(f"✅ Registered test FCM token for user")
    
    # Process reminders
    print(f"\n📤 Processing reminders...")
    result = process_calendar_reminders(calendar_id, enable_push=True)
    
    print(f"\n📊 Notification Results:")
    print(f"   In-App Sent: {result.get('inAppSent', 0)}")
    print(f"   In-App Failed: {result.get('inAppFailed', 0)}")
    print(f"   Push Sent: {result.get('pushSent', 0)}")
    print(f"   Push Failed: {result.get('pushFailed', 0)}")
    print(f"   Total Reminders: {result.get('totalReminders', 0)}")
    
    if result.get('inAppSent', 0) == 0 and result.get('totalReminders', 0) == 0:
        print(f"\n💡 Note: No reminders due today. Reminders are scheduled for:")
        print(f"   - 3 days before activity")
        print(f"   - 1 day before activity")
        print(f"   - Morning of activity")
    
    # Check notifications in Firestore
    notifications = get_user_notifications("9999999999", unread_only=True)
    
    print(f"\n📬 Unread Notifications in Firestore: {len(notifications)}")
    for notif in notifications[:3]:
        print(f"\n   📨 {notif['title']}")
        print(f"      {notif['body'][:80]}...")
        print(f"      Priority: {notif['priority']}")
        print(f"      Action: {notif['actionText']}")


def test_notification_retrieval():
    """Test retrieving user notifications."""
    print("\n" + "=" * 80)
    print("TEST: Notification Retrieval")
    print("=" * 80)
    
    user_id = "9999999999"
    
    # Get unread notifications
    unread = get_user_notifications(user_id, unread_only=True)
    print(f"\n📬 Unread Notifications: {len(unread)}")
    
    # Get all notifications
    all_notifs = get_user_notifications(user_id, unread_only=False)
    print(f"📬 Total Notifications: {len(all_notifs)}")
    
    # Get summary
    summary = get_notification_summary(user_id)
    print(f"\n📊 Notification Summary:")
    print(f"   Total Unread: {summary['totalUnread']}")
    print(f"   Urgent Unread: {summary['urgentUnread']}")
    
    if unread:
        print(f"\n📋 Recent Unread Notifications:")
        for notif in unread[:5]:
            created = notif.get('createdAt')
            print(f"\n   {notif['icon']} {notif['title']}")
            print(f"   {notif['body'][:80]}...")
            print(f"   Priority: {notif['priority']} | Action: {notif['actionText']}")


def test_fcm_token_management():
    """Test FCM token registration and removal."""
    print("\n" + "=" * 80)
    print("TEST: FCM Token Management")
    print("=" * 80)
    
    user_id = "test_user_fcm"
    test_tokens = [
        "test_token_device_1",
        "test_token_device_2",
        "test_token_device_3"
    ]
    
    # Register tokens
    print(f"\n📱 Registering {len(test_tokens)} device tokens...")
    for token in test_tokens:
        success = register_device_token(user_id, token)
        if success:
            print(f"   ✅ Registered: {token}")
    
    # Check user document
    from ..db.firebase_init import db
    user_doc = db.collection("users").document(user_id).get()
    if user_doc.exists:
        user_data = user_doc.to_dict()
        stored_tokens = user_data.get("fcmTokens", [])
        print(f"\n✅ User has {len(stored_tokens)} tokens stored in Firestore")
    
    print(f"\n🔍 Testing OAuth token generation...")
    from .reminder_service import get_access_token
    access_token = get_access_token()
    if access_token:
        print(f"✅ Successfully generated OAuth access token")
        print(f"   Token: {access_token[:30]}...")
    else:
        print(f"❌ Failed to generate access token")


if __name__ == "__main__":
    print("\n🔔 REMINDER SYSTEM TESTS\n")
    
    # Test 1: Reminder generation
    test_reminder_generation()
    
    # Test 2: Today's reminders
    test_todays_reminders()
    
    # Test 3: Send notifications
    test_send_notifications()
    
    # Test 4: Retrieve notifications
    test_notification_retrieval()
    
    # Test 5: FCM token management
    test_fcm_token_management()
    
    print("\n" + "=" * 80)
    print("✅ REMINDER TESTS COMPLETED")
    print("=" * 80)
   