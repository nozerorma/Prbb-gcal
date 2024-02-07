# main.py

from icalendar import Calendar, Event
import requests
from bs4 import BeautifulSoup
from datetime import datetime, timedelta
import re
import logging
from google.cloud import storage

def main(request):
    # Set up logging
    logging.basicConfig(level=logging.ERROR)  # Set the logging level to ERROR

    # Create a new calendar
    cal = Calendar()
    cal.add('X-WR-TIMEZONE', 'Europe/Madrid')

    # Initialize counter
    processed_entries = 0

    # Loop through URLs from xxxx=1000 to xxxx=2000
    for i in range(1, 2000):
        url = f"https://www.prbb.org/agenda-evento.php?id={i}"
        print("Entry:", i)

        try:
            # Fetch the webpage content
            response = requests.get(url)

            # Check if the request was successful
            response.raise_for_status()
            html_content = response.text

            # Parse HTML content
            soup = BeautifulSoup(html_content, 'html.parser')

            try:
                # Extract event information
                date_str = soup.find('small', id='date').text.strip()
                # Extract date, time, and location using regex
                pattern = r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (.+?) (.+)'
                match = re.match(pattern, date_str)
                if match:
                    date_str = match.group(1)
                    location = match.group(2) + " " + match.group(3)
                else:
                    # Fallback if regex match fails
                    date_str, location = date_str.split(' → ', 1)  # Split date and location

                start_time = datetime.strptime(date_str, '%Y-%m-%d %H:%M:%S')  # Parse date
                # Calculate end time as start time + 1 hour
                end_time = start_time + timedelta(hours=1)
                title = soup.find('h3', id='title').text.strip()
                print(title)

                # Extract optional attributes
                speakers_name_element = soup.find('h4', id='speakersName')
                speakers_name = speakers_name_element.text.strip() if speakers_name_element else ''

                affiliation_element = soup.find('h4', id='afiliacion')
                affiliation = affiliation_element.text.strip() if affiliation_element else ''

                descriptor_element = soup.find('div', id='description')
                descriptor = descriptor_element.text.strip() if descriptor_element else ''

                photo_link_element = soup.find('div', id='photo')
                if photo_link_element:
                    img_element = photo_link_element.find('img')
                    if img_element:
                        photo_link = f"https://www.prbb.org{img_element.get('src', '')}"
                    else:
                        photo_link = f"None"
                else:
                    photo_link = f"None"

                # Construct description
                description = f"Speaker: {speakers_name}\nAffiliation: {affiliation}\nDescription: {descriptor}\nPhoto link: {photo_link}"

                # Create an event
                event = Event()
                event.add('summary', title)
                event.add('description', description)
                event.add('dtstart', start_time)
                event.add('dtend', end_time)
                event.add('location', location)

                # Add the event to the calendar
                cal.add_component(event)
                processed_entries += 1
            except requests.exceptions.RequestException as e:
                logging.error(f"Error processing event {url}: {e}")
                continue
        except Exception as e:
            logging.error(f"Error processing event {url}: {e}")
            continue

    # Create a Cloud Storage client
    storage_client = storage.Client()

    # Get a bucket reference
    bucket = storage_client.bucket('ical_bucket')

    # Create a blob object
    blob = bucket.blob('events.ics')

    # Write the calendar data to the blob
    blob.upload_from_string(cal.to_ical(), content_type='text/calendar')

    # Return a response indicating success
    print("iCal file created successfully!")
    print("Processed entries: ", processed_entries)

    return 'iCal file created successfully!', 200

# The following is for local testing only, it will not be used in Google Cloud Function environment
if __name__ == "__main__":
    main(None)
