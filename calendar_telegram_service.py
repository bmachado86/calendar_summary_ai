#!/usr/bin/env python3
"""
Google Calendar to Telegram Daily Summary Service

This script fetches today's events from Google Calendar and sends a summary
to a specified Telegram chat.

Requirements:
- Google Calendar API credentials (credentials.json)
- Telegram Bot Token
- Telegram Chat ID

Usage:
    python calendar_telegram_service.py
"""

import os
import json
import datetime
import requests
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

# Google Calendar API scopes
SCOPES = ['https://www.googleapis.com/auth/calendar.readonly']

# Configuration
CREDENTIALS_FILE = 'credentials.json'
TOKEN_FILE = 'token.json'
TELEGRAM_BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')
TELEGRAM_CHAT_ID = os.getenv('TELEGRAM_CHAT_ID')

def authenticate_google_calendar():
    """
    Authenticate with Google Calendar API using OAuth 2.0.
    
    Returns:
        service: Google Calendar API service object
    """
    creds = None
    
    # Load existing token if available
    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
    
    # If there are no (valid) credentials available, let the user log in
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            if not os.path.exists(CREDENTIALS_FILE):
                raise FileNotFoundError(f"Credentials file '{CREDENTIALS_FILE}' not found. "
                                      "Please download it from Google Cloud Console.")
            
            flow = InstalledAppFlow.from_client_secrets_file(CREDENTIALS_FILE, SCOPES)
            creds = flow.run_local_server(port=0)
        
        # Save the credentials for the next run
        with open(TOKEN_FILE, 'w') as token:
            token.write(creds.to_json())
    
    try:
        service = build('calendar', 'v3', credentials=creds)
        return service
    except HttpError as error:
        print(f'An error occurred: {error}')
        return None

def get_today_events(service):
    """
    Fetch today's events from Google Calendar.
    
    Args:
        service: Google Calendar API service object
        
    Returns:
        list: List of today's events
    """
    # Get today's date range
    today = datetime.date.today()
    start_time = datetime.datetime.combine(today, datetime.time.min).isoformat() + 'Z'
    end_time = datetime.datetime.combine(today, datetime.time.max).isoformat() + 'Z'
    
    try:
        # Call the Calendar API
        events_result = service.events().list(
            calendarId='primary',
            timeMin=start_time,
            timeMax=end_time,
            singleEvents=True,
            orderBy='startTime'
        ).execute()
        
        events = events_result.get('items', [])
        return events
        
    except HttpError as error:
        print(f'An error occurred while fetching events: {error}')
        return []

def format_event_summary(events):
    """
    Format the events into a readable summary.
    
    Args:
        events (list): List of calendar events
        
    Returns:
        str: Formatted summary text
    """
    if not events:
        return "📅 No events scheduled for today. Enjoy your free day!"
    
    today = datetime.date.today()
    summary = f"📅 **Calendar Summary for {today.strftime('%A, %B %d, %Y')}**\n\n"
    
    for i, event in enumerate(events, 1):
        # Get event title
        title = event.get('summary', 'No Title')
        
        # Get event time
        start = event['start'].get('dateTime', event['start'].get('date'))
        end = event['end'].get('dateTime', event['end'].get('date'))
        
        # Format time
        if 'T' in start:  # DateTime event
            start_dt = datetime.datetime.fromisoformat(start.replace('Z', '+00:00'))
            end_dt = datetime.datetime.fromisoformat(end.replace('Z', '+00:00'))
            time_str = f"{start_dt.strftime('%I:%M %p')} - {end_dt.strftime('%I:%M %p')}"
        else:  # All-day event
            time_str = "All day"
        
        # Get location if available
        location = event.get('location', '')
        location_str = f"\n📍 {location}" if location else ""
        
        # Get description if available
        description = event.get('description', '')
        desc_str = f"\n📝 {description[:100]}..." if description and len(description) > 100 else f"\n📝 {description}" if description else ""
        
        summary += f"{i}. **{title}**\n⏰ {time_str}{location_str}{desc_str}\n\n"
    
    summary += f"Total events: {len(events)}"
    return summary

def send_telegram_message(message):
    """
    Send a message to Telegram using the Bot API.
    
    Args:
        message (str): Message to send
        
    Returns:
        bool: True if successful, False otherwise
    """
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
        print("Error: TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID environment variables must be set")
        return False
    
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    
    payload = {
        'chat_id': TELEGRAM_CHAT_ID,
        'text': message,
        'parse_mode': 'Markdown'
    }
    
    try:
        response = requests.post(url, json=payload)
        response.raise_for_status()
        
        result = response.json()
        if result.get('ok'):
            print("Message sent successfully to Telegram")
            return True
        else:
            print(f"Failed to send message: {result.get('description', 'Unknown error')}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"Error sending message to Telegram: {e}")
        return False

def main():
    """
    Main function to run the calendar summary service.
    """
    print("Starting Google Calendar to Telegram Summary Service...")
    
    # Authenticate with Google Calendar
    print("Authenticating with Google Calendar...")
    service = authenticate_google_calendar()
    if not service:
        print("Failed to authenticate with Google Calendar")
        return
    
    # Fetch today's events
    print("Fetching today's events...")
    events = get_today_events(service)
    
    # Format the summary
    print("Formatting event summary...")
    summary = format_event_summary(events)
    
    # Send to Telegram
    print("Sending summary to Telegram...")
    success = send_telegram_message(summary)
    
    if success:
        print("Daily calendar summary sent successfully!")
    else:
        print("Failed to send daily calendar summary")

if __name__ == '__main__':
    main()

