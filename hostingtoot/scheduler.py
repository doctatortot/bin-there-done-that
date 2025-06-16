from mastodon import Mastodon
import schedule
import time

# Mastodon instance URL and access token
api_base_url = 'https://chatwithus.live'
access_token = 'orRX9FzHIc0AH1Y3m1BdrI3DWNECPpvuR0PxFwu5FaI'

# List of predefined toots with their scheduled times and days of the week
toots = [
    {"message": "Hello, Mastodon!", "time": "07:07", "day": "sunday"},
    {"message": "This is a test toot.", "time": "15:00", "day": "tuesday"},
    {"message": "Posting to Mastodon with Python!", "time": "15:30", "day": "wednesday"},
    {"message": "Automated toots are fun!", "time": "16:00", "day": "thursday"},
    {"message": "Have a great day!", "time": "16:30", "day": "friday"}
]

# Initialize Mastodon API
mastodon = Mastodon(
    access_token=access_token,
    api_base_url=api_base_url
)

def post_toot(message):
    mastodon.status_post(message)
    print(f"Posted toot: {message}")

# Schedule each toot
for toot in toots:
    schedule_time = toot["time"]
    schedule_message = toot["message"]
    schedule_day = toot["day"].lower()

    # Schedule the toot based on the day of the week
    if schedule_day == "monday":
        schedule.every().monday.at(schedule_time).do(post_toot, message=schedule_message)
    elif schedule_day == "tuesday":
        schedule.every().tuesday.at(schedule_time).do(post_toot, message=schedule_message)
    elif schedule_day == "wednesday":
        schedule.every().wednesday.at(schedule_time).do(post_toot, message=schedule_message)
    elif schedule_day == "thursday":
        schedule.every().thursday.at(schedule_time).do(post_toot, message=schedule_message)
    elif schedule_day == "friday":
        schedule.every().friday.at(schedule_time).do(post_toot, message=schedule_message)
    elif schedule_day == "saturday":
        schedule.every().saturday.at(schedule_time).do(post_toot, message=schedule_message)
    elif schedule_day == "sunday":
        schedule.every().sunday.at(schedule_time).do(post_toot, message=schedule_message)

# Run the scheduler
while True:
    schedule.run_pending()
    time.sleep(1)
