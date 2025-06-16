import os
import time
import re
from urllib.parse import quote
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from mastodon import Mastodon, MastodonError

# Configuration
SHOW_NAMES = {
    "retro": "The Retro Breakfast",
    "90slunch": "90s Lunch",
    "80sdimension": "80s Dimension",
    "au": "Alternate Universe",
    "bootycalls": "Booty Calls",
    "chaos": "Chaos",
    "gog": "Gog",
    "housecalls": "House Calls",
    "mac": "March of the Mac",
    "yes": "Yes Series",
    "welch": "Bob Welch Special",
    "wakeman": "Caped Crusader: The Rick Wakeman Retrospective",
    "mayhem": "Mayhem",
    "pisces": "Pisces Playhouse",
    "rockvault": "Rock Vault",
    "sonicrevolt": "Sonic Revolt",
    "tunefuse": "TuneFuse",
    "wwo80s": "WWO 80s",
    "yacht": "Yacht Rock",
}

BASE_URL = "http://server.genesis-radio.net:5020"
INSTANCE_URL = "https://chatwithus.live"
ACCESS_TOKEN = "qTtckG3g7oBwVPAzhkuq_LyVHbDgwwYtX0YkV5rbczI"

mastodon = Mastodon(
    access_token=ACCESS_TOKEN,
    api_base_url=INSTANCE_URL
)

# Keep track of files processed and the time they were processed
processed_files = {}
DEBOUNCE_TIME = 5  # Time in seconds to wait before processing the same file again

# Improved show name extraction based on directory aliasing
def extract_show_name(file_path):
    parent_dir = os.path.basename(os.path.dirname(file_path))
    return SHOW_NAMES.get(parent_dir, "Genesis Radio")

class FileEventHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.is_directory:
            return

        # Only process .mp3 files
        if not event.src_path.endswith('.mp3'):
            print(f"Skipping non-mp3 file: {event.src_path}")
            return

        current_time = time.time()  # Get the current time in seconds

        # If the file has been processed within the debounce window, skip it
        if event.src_path in processed_files:
            last_processed_time = processed_files[event.src_path]
            if current_time - last_processed_time < DEBOUNCE_TIME:
                print(f"Skipping duplicate event for file: {event.src_path}")
                return

        # Update the time of processing for this file
        processed_files[event.src_path] = current_time

        # Debugging: Confirm file creation detection
        print(f"File detected: {event.src_path}")

        file_path = event.src_path
        filename = os.path.basename(file_path)
        show_name = extract_show_name(file_path)

        # URL encode the filename and parent directory
        encoded_filename = quote(filename, safe='')
        parent_dir = os.path.basename(os.path.dirname(file_path))
        encoded_parent_dir = quote(parent_dir, safe='')

        # Construct the file URL to go to the new path format
        file_url = f"{BASE_URL}/show/{encoded_parent_dir}"

        # Constructing a cleaner and more engaging Mastodon message
        message = f"🎉 New Archive Alert! 🎧 {show_name}'s latest episode is now available! 🎶\n\nTune in: {file_url}"

        # Debugging: Check the message before posting
        print(f"Message to post: {message}")

        try:
            mastodon.status_post(message)
            print("✅ Successfully posted.")
        except MastodonError as e:
            print(f"❌ Mastodon API Error: {e}")
            print(f"Full error: {e.args}")

if __name__ == "__main__":
    observer = Observer()
    handler = FileEventHandler()

    valid_directories = []
    for directory in SHOW_NAMES.keys():
        directory_path = os.path.join("/mnt/convert/archives", directory)
        if os.path.exists(directory_path):
            print(f"✅ Monitoring: {directory_path}")
            valid_directories.append(directory_path)
        else:
            print(f"❌ Skipping non-existent directory: {directory_path}")

    if not valid_directories:
        print("❌ No valid directories found to monitor. Exiting.")
        exit(1)

    for directory in valid_directories:
        observer.schedule(handler, directory, recursive=False)

    print("🔔 Genesis Radio Mastodon Notifier running. Press Ctrl+C to stop.")
    observer.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n🔒 Shutting down observer...")
        observer.stop()

    observer.join()
