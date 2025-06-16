import os
import subprocess
import json
from apscheduler.schedulers.background import BackgroundScheduler
from flask import Flask, render_template, request, redirect, url_for

app = Flask(__name__)
scheduler = BackgroundScheduler()

CONFIG_FILE = "show_schedule.json"

# Display names mapping for shows
DISPLAY_NAMES = {
    "80sdimension": "The 80s Dimension",
    "90slunch": "The 90s Lunch",
    "au": "Alternate Universe",
    "welch": "Bob Welch Retrospective",
    "bootycalls": "Booty Calls",
    "chaos": "The Chaos Bus",
    "mac": "Fleetwood Mac Retrospective",
    "gog": "The Good Ol Genesis",
    "housecalls": "House Calls",
    "pisces": "Pisces Playhouse",
    "retro": "The Retro Breakfast",
    "rockvault": "Rock Vault",
    "mayhem": "Rock and Roll Mayhem",
    "wakeman": "Rick Wakeman Retrospective",
    "sonicrevolt": "Sonic Revolt",
    "tunefuse": "TuneFuse",
    "wwo80s": "We Want Our 80s",
    "yacht": "Yacht Vibes Only",
    "yes": "Yes Retrospective"
}

# Ensure config file exists
if not os.path.exists(CONFIG_FILE):
    with open(CONFIG_FILE, "w") as f:
        json.dump({}, f)

# Load show schedule data from JSON
def load_show_schedule():
    with open(CONFIG_FILE, "r") as f:
        return json.load(f)

# Save show schedule data to JSON
def save_show_schedule(data):
    with open(CONFIG_FILE, "w") as f:
        json.dump(data, f, indent=4)

# Call external script to do the recording
def record_show(show_name, duration):
    print(f"[+] Starting recording: {show_name} for {duration} seconds")
    subprocess.run(["python3", "recordtheshow.py", show_name, str(duration)])

# Flask route: Homepage with schedule overview
@app.route('/')
def index():
    shows = load_show_schedule()
    return render_template("index.html", shows=shows, display_names=DISPLAY_NAMES)

# Flask route: Toggle recording on/off
@app.route('/toggle/<show_name>', methods=['POST'])
def toggle_recording(show_name):
    shows = load_show_schedule()
    if show_name in shows:
        shows[show_name]["recording"] = not shows[show_name]["recording"]
    else:
        shows[show_name] = {
            "recording": True,
            "duration": 1800,
            "schedule": []
        }
    save_show_schedule(shows)
    schedule_show_recordings()
    return redirect(url_for('index'))

# Flask route: Update schedule from form
@app.route('/update_schedule/<show_name>', methods=['POST'])
def update_schedule(show_name):
    shows = load_show_schedule()
    new_schedule = request.form.getlist('schedule')

    schedule_entries = []
    for entry in new_schedule:
        if ' ' in entry:
            day, time = entry.split(' ', 1)
            schedule_entries.append({"day": day.strip(), "time": time.strip()})

    if show_name not in shows:
        shows[show_name] = {
            "recording": True,
            "duration": 1800,
            "schedule": schedule_entries
        }
    else:
        shows[show_name]["schedule"] = schedule_entries

    save_show_schedule(shows)
    schedule_show_recordings()
    return redirect(url_for('index'))

# Reschedule all active recordings
def schedule_show_recordings():
    scheduler.remove_all_jobs()
    shows = load_show_schedule()

    weekday_map = {
        "monday": "mon",
        "tuesday": "tue",
        "wednesday": "wed",
        "thursday": "thu",
        "friday": "fri",
        "saturday": "sat",
        "sunday": "sun"
    }

    for show_name, settings in shows.items():
        if settings.get("recording", False):
            duration = settings.get("duration", 1800)
            for slot in settings.get("schedule", []):
                day_full = slot.get("day", "").lower()
                day = weekday_map.get(day_full)
                if not day:
                    print(f"[!] Skipping {show_name} — invalid day: {day_full}")
                    continue

                time_str = slot.get("time", "00:00")
                try:
                    hour, minute = map(int, time_str.split(":"))
                    scheduler.add_job(
                        record_show,
                        'cron',
                        day_of_week=day,
                        hour=hour,
                        minute=minute,
                        args=[show_name, duration],
                        id=f"{show_name}_{day}_{hour}{minute}"
                    )
                    print(f"[✓] Scheduled: {show_name} on {day} at {time_str} for {duration}s")
                except Exception as e:
                    print(f"[!] Failed to schedule {show_name}: {e}")

    # Only start scheduler once
    if not scheduler.running:
        scheduler.start()

# Run the Flask app externally
if __name__ == '__main__':
    schedule_show_recordings()
    app.run(host="0.0.0.0", port=5021, debug=True)
