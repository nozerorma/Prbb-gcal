from google.oauth2 import service_account
from googleapiclient.discovery import build

# Set up credentials (OAuth 2.0)
credentials = service_account.Credentials.from_service_account_file('cred/credentials.json')

# Authenticate with the Calendar API
service = build('calendar', 'v3', credentials=credentials)

# Define the calendar ID of the target Google Calendar
# TODO: Replace with your Google Calendar ID
calendar_id = 'YOUR_CALENDAR_ID_HERE@group.calendar.google.com'


# Read the contents of the .ics file
with open('events.ics', 'r') as f:
    ics_content = f.read()

# Upload the events from the .ics file to the specified Google Calendar
events = service.events().import_(calendarId=calendar_id, body=ics_content).execute()

print('Events imported successfully!')
