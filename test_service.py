#!/usr/bin/env python3
"""
Test script for the Google Calendar to Telegram service.

This script tests individual components without requiring actual credentials.
"""

import os
import json
import datetime
from unittest.mock import Mock, patch
import sys

# Add the current directory to the path so we can import our service
sys.path.append('.')

def test_format_event_summary():
    """Test the event formatting function."""
    print("Testing event formatting...")
    
    # Import the function from our service
    from calendar_telegram_service import format_event_summary
    
    # Test with no events
    empty_events = []
    result = format_event_summary(empty_events)
    assert "No events scheduled for today" in result
    print("✓ Empty events test passed")
    
    # Test with sample events
    sample_events = [
        {
            'summary': 'Team Meeting',
            'start': {'dateTime': '2025-07-08T09:00:00Z'},
            'end': {'dateTime': '2025-07-08T10:00:00Z'},
            'location': 'Conference Room A',
            'description': 'Weekly team sync meeting'
        },
        {
            'summary': 'Lunch Break',
            'start': {'date': '2025-07-08'},
            'end': {'date': '2025-07-08'},
        },
        {
            'summary': 'Project Review',
            'start': {'dateTime': '2025-07-08T14:00:00Z'},
            'end': {'dateTime': '2025-07-08T15:30:00Z'},
            'description': 'Review the quarterly project progress and discuss next steps for the upcoming quarter'
        }
    ]
    
    result = format_event_summary(sample_events)
    assert "Team Meeting" in result
    assert "Lunch Break" in result
    assert "Project Review" in result
    assert "Conference Room A" in result
    assert "Total events: 3" in result
    print("✓ Sample events test passed")
    
    print("Event formatting tests completed successfully!\n")

def test_telegram_message_format():
    """Test that the Telegram message format is valid."""
    print("Testing Telegram message format...")
    
    from calendar_telegram_service import format_event_summary
    
    # Create a sample event with special characters
    sample_events = [
        {
            'summary': 'Meeting with *special* characters & symbols',
            'start': {'dateTime': '2025-07-08T09:00:00Z'},
            'end': {'dateTime': '2025-07-08T10:00:00Z'},
        }
    ]
    
    result = format_event_summary(sample_events)
    
    # Check that the message contains Markdown formatting
    assert "**" in result  # Bold formatting
    assert "📅" in result  # Calendar emoji
    assert "⏰" in result  # Clock emoji
    
    print("✓ Telegram message format test passed")
    print("Telegram message format tests completed successfully!\n")

def test_environment_variables():
    """Test environment variable handling."""
    print("Testing environment variable handling...")
    
    # Test with missing environment variables
    old_token = os.environ.get('TELEGRAM_BOT_TOKEN')
    old_chat_id = os.environ.get('TELEGRAM_CHAT_ID')
    
    # Remove environment variables temporarily
    if 'TELEGRAM_BOT_TOKEN' in os.environ:
        del os.environ['TELEGRAM_BOT_TOKEN']
    if 'TELEGRAM_CHAT_ID' in os.environ:
        del os.environ['TELEGRAM_CHAT_ID']
    
    from calendar_telegram_service import send_telegram_message
    
    # This should return False due to missing environment variables
    result = send_telegram_message("Test message")
    assert result == False
    print("✓ Missing environment variables test passed")
    
    # Restore environment variables if they existed
    if old_token:
        os.environ['TELEGRAM_BOT_TOKEN'] = old_token
    if old_chat_id:
        os.environ['TELEGRAM_CHAT_ID'] = old_chat_id
    
    print("Environment variable tests completed successfully!\n")

def test_date_handling():
    """Test date and time handling."""
    print("Testing date and time handling...")
    
    from calendar_telegram_service import format_event_summary
    
    # Test with different date formats
    events_with_dates = [
        {
            'summary': 'All Day Event',
            'start': {'date': '2025-07-08'},
            'end': {'date': '2025-07-08'},
        },
        {
            'summary': 'Timed Event',
            'start': {'dateTime': '2025-07-08T14:30:00Z'},
            'end': {'dateTime': '2025-07-08T15:45:00Z'},
        }
    ]
    
    result = format_event_summary(events_with_dates)
    assert "All day" in result
    assert "PM" in result  # Should show time for timed events
    
    print("✓ Date handling test passed")
    print("Date handling tests completed successfully!\n")

def run_all_tests():
    """Run all tests."""
    print("=" * 50)
    print("Running Google Calendar to Telegram Service Tests")
    print("=" * 50)
    print()
    
    try:
        test_format_event_summary()
        test_telegram_message_format()
        test_environment_variables()
        test_date_handling()
        
        print("=" * 50)
        print("🎉 ALL TESTS PASSED! 🎉")
        print("=" * 50)
        print()
        print("The service components are working correctly.")
        print("You can now proceed with setting up the actual credentials.")
        
    except Exception as e:
        print("=" * 50)
        print("❌ TEST FAILED!")
        print("=" * 50)
        print(f"Error: {e}")
        print()
        print("Please check the service code and try again.")

if __name__ == '__main__':
    run_all_tests()

