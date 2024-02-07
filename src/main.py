# Unparallelized

from icalendar import Calendar, Event
import requests
from bs4 import BeautifulSoup
from datetime import datetime, timedelta
import re
import logging
from google.cloud import storage
from concurrent.futures import ThreadPoolExecutor

# Dictionary to store cached HTML content
html_cache = {}

def fetch_url_content(url):
    try:
        # Check if the content is already cached
        if url in html_cache:
            html_content = html_cache[url]
        else:
            response = requests.get(url)
            response.raise_for_status()
            html_content = response.text
            # Cache the HTML content
            html_cache[url] = html_content
        return html_content
    except Exception as e:
        logging.error(f"Error fetching URL {url}: {e}")
        return None

def process_event(url):
    try:
        html_content = fetch_url_content(url)
        if html_content:
            soup = BeautifulSoup(html_content, 'html.parser')
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

            return event
    except Exception as e:
        logging.error(f"Error processing event {url}: {e}")
        return None

def main(request):
    logging.basicConfig(level=logging.ERROR)  # Set the logging level to ERROR

    cal = Calendar()
    cal.add('X-WR-TIMEZONE', 'Europe/Madrid')
    processed_entries = 0

    with ThreadPoolExecutor(max_workers=10) as executor:
        # Loop through URLs in parallel
        futures = []
        for i in range(1, 2000):
            url = f"https://www.prbb.org/agenda-evento.php?id={i}"
            futures.append(executor.submit(process_event, url))

        for future in futures:
            event = future.result()
            if event:
                cal.add_component(event)
                processed_entries += 1

# # Local
#     # Write the calendar to a file
#     with open('events.ics', 'wb') as f:
#         f.write(cal.to_ical())

# Cloud
    storage_client = storage.Client()
    bucket = storage_client.bucket('ical_bucket')
    blob = bucket.blob('events.ics')
    blob.upload_from_string(cal.to_ical(), content_type='text/calendar')

    print("iCal file created successfully!")
    print("Processed entries: ", processed_entries)

    return 'iCal file created successfully!', 200

if __name__ == "__main__":
    main(None)
