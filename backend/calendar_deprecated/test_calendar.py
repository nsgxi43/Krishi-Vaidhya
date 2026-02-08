# kvb/calendar/test_calendar.py
"""
Test script with accurate data sources displayed.
"""

from datetime import datetime
from .calendar_service import generate_calendar, get_calendar_progress, get_upcoming_activities
from .crop_data_accurate import get_available_crops, get_crop_lifecycle
from ..location.location_service import normalize_location
from ..db.calendar_db_service import save_calendar


def test_accurate_calendar():
    """Test calendar with accurate data."""
    print("=" * 80)
    print("TEST: Accurate Crop Calendar (ICAR Data)")
    print("=" * 80)
    
    # Get crop info
    crop_data = get_crop_lifecycle("Tomato")
    
    print(f"\n📊 Data Source Information:")
    print(f"   Scientific Name: {crop_data['scientific_name']}")
    print(f"   Data Source: {crop_data['data_source']}")
    print(f"   Validation Status: {crop_data['validation_status']}")
    print(f"   Last Updated: {crop_data['last_updated']}")
    
    print(f"\n🌾 Recommended Varieties (Karnataka):")
    for variety in crop_data['recommended_varieties']['Karnataka']:
        print(f"   - {variety}")
    
    print(f"\n📅 Sowing Seasons:")
    for season, months in crop_data['sowing_seasons'].items():
        print(f"   - {season}: {months}")
    
    # Generate calendar
    location = normalize_location(12.9716, 77.5946)
    today = datetime.now().strftime("%Y-%m-%d")
    
    calendar = generate_calendar(
        crop="Tomato",
        sowing_date=today,
        location=location,
        user_id="farmer_001"
    )
    
    print(f"\n✅ Calendar Generated")
    print(f"   Duration: {calendar['durationDays']} days")
    print(f"   Expected Harvest: {calendar['expectedHarvestDate']}")
    print(f"   Total Activities: {len(calendar['lifecycle'])}")
    print(f"   Data Source: {calendar['dataSource']}")
    print(f"   Validation: {calendar['validationStatus']}")
    
    print(f"\n📋 Key Activities with Full Details:")
    print("-" * 80)
    for activity in calendar['lifecycle'][:10]:
        print(f"Day {activity['dayOffset']:3d} ({activity['scheduledDate']}): {activity['name']}")
        print(f"         Category: {activity['category']}")
        print(f"         Source: {activity.get('source', '❌ MISSING')}")
        print(f"         Description: {activity['description'][:60]}...")
        print()
    
    # Get progress
    progress = get_calendar_progress(calendar)
    print(f"📊 Calendar Progress:")
    print(f"   Completed: {progress['completed']}/{progress['totalActivities']} ({progress['progressPercent']}%)")
    print(f"   Days Elapsed: {progress['daysElapsed']}")
    print(f"   Days Remaining: {progress['daysRemaining']}")
    
    # Get upcoming activities
    upcoming = get_upcoming_activities(calendar, days_ahead=14)
    print(f"\n📅 Upcoming Activities (Next 14 Days): {len(upcoming)}")
    for activity in upcoming[:5]:
        print(f"   - {activity['scheduledDate']}: {activity['name']} (in {activity['daysUntil']} days)")
    
    # Save
    calendar_id = save_calendar(calendar)
    print(f"\n💾 Saved to Firestore: {calendar_id}")
    
    return calendar_id


def test_all_crops_validation():
    """Test all available crops to ensure data quality."""
    print("\n" + "=" * 80)
    print("TEST: All Crops Validation")
    print("=" * 80)
    
    crops = get_available_crops()
    print(f"\n🌾 Testing {len(crops)} crops for data completeness:")
    
    location = normalize_location(12.9716, 77.5946)
    today = datetime.now().strftime("%Y-%m-%d")
    
    issues = []
    
    for crop in crops:
        try:
            crop_data = get_crop_lifecycle(crop)
            calendar = generate_calendar(
                crop=crop,
                sowing_date=today,
                location=location,
                user_id="validator"
            )
            
            # Check if all activities have sources
            missing_sources = 0
            for activity in calendar['lifecycle']:
                if activity.get('source') in [None, 'N/A', 'Standard practice']:
                    missing_sources += 1
            
            if missing_sources > 0:
                status = f"⚠️  {crop}: {missing_sources} activities missing detailed source"
                issues.append(status)
            else:
                status = f"✅ {crop}: All {len(calendar['lifecycle'])} activities validated"
            
            print(f"   {status}")
            
        except Exception as e:
            error_msg = f"❌ {crop}: ERROR - {str(e)}"
            print(f"   {error_msg}")
            issues.append(error_msg)
    
    if issues:
        print(f"\n⚠️  Found {len(issues)} issues:")
        for issue in issues:
            print(f"   {issue}")
    else:
        print(f"\n✅ All crops validated successfully!")


if __name__ == "__main__":
    print("\n🌱 ACCURATE CROP CALENDAR TEST\n")
    
    # Test 1: Detailed calendar test
    calendar_id = test_accurate_calendar()
    
    # Test 2: Validate all crops
    test_all_crops_validation()
    
    print("\n" + "=" * 80)
    print("✅ ALL TESTS COMPLETED")
    print("=" * 80)