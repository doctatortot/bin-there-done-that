import os
from flask import Flask, render_template_string, send_from_directory, abort
from mastodon import Mastodon

# === Configuration ===

ROOT_DIR = r"/mnt/archives"  # Update this path to where your shows live
ALLOWED_EXTENSIONS = {".mp3", ".wav", ".flac", ".m4a"}
BANNER_FILENAMES = ["banner.jpg", "banner.png", "banner.jpeg"]

# Friendly display names
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
    "yes": "Yes Retrospective",
}

# === URLs for File Hosting ===

BASE_URL = "http://server.genesis-radio.net:5020"  # This is the base URL where your files live (e.g., http://localhost:5000)

SERVER_URL = "http://genesis-radio.net"  # This is the general server URL if you need it for anything else

# === Flask App ===

app = Flask(__name__)

HOME_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Genesis Radio Archives</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #111; color: #eee; margin: 2em; }
        h1 { font-size: 2em; color: #0ff; border-bottom: 2px solid #0ff; padding-bottom: 0.5em; }
        ul { list-style: none; padding-left: 0; }
        li { margin: 1em 0; }
        a { color: #0cf; font-size: 1.3em; text-decoration: none; font-weight: bold; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <h1>Genesis Radio: Show Archives</h1>
    <ul>
        {% for show in shows %}
            <li><a href="{{ url_for('show_page', show_name=show) }}">{{ display_names.get(show, show) }}</a></li>
        {% endfor %}
    </ul>
</body>
</html>
"""

SHOW_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>{{ show_name }} - Genesis Radio</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #111; color: #eee; margin: 2em; }
        a { color: #0cf; text-decoration: none; }
        a:hover { text-decoration: underline; }
        h1 { color: #0ff; font-size: 1.8em; margin-bottom: 1em; border-bottom: 2px solid #0ff; padding-bottom: 0.3em; }
        .back { margin-bottom: 1.5em; display: inline-block; color: #0cf; }
        .audio-block { margin-bottom: 2em; }
        p { font-weight: bold; color: #fff; }
        audio { width: 100%; }
        .banner { width: 100%; max-height: 250px; object-fit: cover; margin-bottom: 1em; }
    </style>
</head>
<body>
    <a href="{{ url_for('index') }}" class="back">&larr; Back to shows</a>
    <h1>{{ display_names.get(show_name, show_name) }}</h1>
    {% if banner %}
        <img src="{{ url_for('show_banner', show_name=show_name, banner_name=banner) }}" class="banner">
    {% endif %}
    {% for file in files %}
        <div class="audio-block">
            <p>{{ file }}</p>
            <audio controls>
                <source src="{{ url_for('stream_file', show=show_name, filename=file) }}" type="audio/mpeg">
                Your browser does not support the audio element.
            </audio>
        </div>
    {% else %}
        <p>No audio files found for this show.</p>
    {% endfor %}
</body>
</html>
"""

# === Utility Functions ===

def list_shows(base_dir):
    return sorted([d for d in os.listdir(base_dir) if os.path.isdir(os.path.join(base_dir, d))])

def list_audio_files(show_dir):
    return sorted([
        f for f in os.listdir(show_dir)
        if os.path.splitext(f)[1].lower() in ALLOWED_EXTENSIONS
    ])

def find_banner(show_dir):
    for name in BANNER_FILENAMES:
        if os.path.isfile(os.path.join(show_dir, name)):
            return name
    return None

# === Flask Routes ===

@app.route("/")
def index():
    shows = list_shows(ROOT_DIR)
    return render_template_string(HOME_TEMPLATE, shows=shows, display_names=DISPLAY_NAMES)

@app.route("/show/<show_name>")
def show_page(show_name):
    show_path = os.path.join(ROOT_DIR, show_name)
    if not os.path.isdir(show_path):
        abort(404)
    files = list_audio_files(show_path)
    banner = find_banner(show_path)
    return render_template_string(SHOW_TEMPLATE, show_name=show_name, files=files, banner=banner, display_names=DISPLAY_NAMES)

@app.route("/stream/<show>/<path:filename>")
def stream_file(show, filename):
    safe_path = os.path.join(ROOT_DIR, show)
    if os.path.isfile(os.path.join(safe_path, filename)):
        return send_from_directory(safe_path, filename, as_attachment=False)
    else:
        abort(404)

@app.route("/banner/<show_name>/<banner_name>")
def show_banner(show_name, banner_name):
    show_path = os.path.join(ROOT_DIR, show_name)
    if os.path.isfile(os.path.join(show_path, banner_name)):
        return send_from_directory(show_path, banner_name)
    else:
        abort(404)

# === Start Everything ===

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5020, debug=True)
