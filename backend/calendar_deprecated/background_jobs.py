# kvb/calendar/background_jobs.py
"""
Background jobs for calendar system.
Run these periodically to:
- Check weather and reschedule
- Send reminders
- Update calendar status
"""

import time
from datetime import datetime
from .reminder_service import process_calendar_reminders
from .scheduler import auto_reschedule_calendar
from ..db.calendar_db_service import get_active_calendars, update_calendar


def process_all_active_calendars():
    """
    Process all active calendars:
    - Check weather
    - Reschedule if needed
    - Send reminders
    """
    print("\n" + "=" * 80)
    print(f"🔄 BACKGROUND JOB STARTED: {datetime.now().isoformat()}")
    print("=" * 80)
    
    calendars = get_active_calendars()
    print(f"\n📊 Found {len(calendars)} active calendar(s)")
    
    for calendar in calendars:
        calendar_id = calendar["calendarId"]
        user_id = calendar["userId"]
        crop = calendar["crop"]
        
        print(f"\n📅 Processing: {crop} calendar for user {user_id}")
        
        try:
            # 1. Check weather and reschedule
            print(f"   🌦️  Checking weather forecast...")
            updated_calendar, evaluation = auto_reschedule_calendar(calendar)
            
            if evaluation["needsRescheduling"]:
                print(f"   ✅ Rescheduled {len(evaluation['recommendations'])} activities")
                update_calendar(calendar_id, updated_calendar)
            else:
                print(f"   ✅ No rescheduling needed")
            
            # 2. Process reminders
            print(f"   🔔 Processing reminders...")
            reminder_result = process_calendar_reminders(calendar_id)
            print(f"   ✅ Sent {reminder_result['remindersSent']} reminders")
        
        except Exception as e:
            print(f"   ❌ Error processing calendar: {e}")
    
    print("\n" + "=" * 80)
    print(f"✅ BACKGROUND JOB COMPLETED: {datetime.now().isoformat()}")
    print("=" * 80)


def run_scheduler(interval_hours: int = 6):
    """
    Run background job scheduler.
    
    Args:
        interval_hours: Hours between runs
    """
    print(f"\n🚀 Calendar Background Scheduler Started")
    print(f"   Interval: Every {interval_hours} hours")
    print(f"   Press Ctrl+C to stop\n")
    
    try:
        while True:
            process_all_active_calendars()
            
            print(f"\n😴 Sleeping for {interval_hours} hours...")
            time.sleep(interval_hours * 3600)
    
    except KeyboardInterrupt:
        print("\n\n🛑 Scheduler stopped by user")


if __name__ == "__main__":
    # Run once for testing
    process_all_active_calendars()