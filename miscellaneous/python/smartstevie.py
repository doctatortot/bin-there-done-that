import requests
import time
from mastodon import Mastodon

# === CONFIGURATION ===
ICECAST_JSON_URL = ""
SONG_TRIGGER = "Spiderbait - Stevie"
MASTODON_BASE_URL = "https://chatwithus.live"
MASTODON_TOKEN = ""  # replace with your token
TOOT_TEXT = "AH BUU BUU BUU BUU"

# --- END CONFIG ---

masto = Mastodon(
    access_token=MASTODON_TOKEN,
    api_base_url=MASTODON_BASE_URL
)

last_seen = False

while True:
    try:
        resp = requests.get(ICECAST_JSON_URL, timeout=10)
        data = resp.json()
        # Correct place to look is data["icestats"]["source"]
        sources = data.get("icestats", {}).get("source")

        if sources is None:
            print("No sources found in Icecast status.")
            time.sleep(30)
            continue

        # If it's a list, find a source with a title or currently playing track
        if isinstance(sources, list):
            main_source = None
            for src in sources:
                if src.get("title") or src.get("yp_currently_playing"):
                    main_source = src
                    break
            if not main_source:
                main_source = sources[0]
        elif isinstance(sources, dict):
            main_source = sources
        else:
            print("No valid sources found.")
            time.sleep(30)
            continue

        now_playing = main_source.get("title") or main_source.get("yp_currently_playing", "")
        now_playing = now_playing.strip()
        print("Now playing:", now_playing)

        # Only toot if the song is playing and it wasn't seen last poll
        if SONG_TRIGGER.lower() in now_playing.lower():
            if not last_seen:
                masto.status_post(TOOT_TEXT, visibility='public')
                print(f"Tooted: {TOOT_TEXT}")
                last_seen = True
        else:
            last_seen = False

    except Exception as e:
        print(f"Error: {e}")

    time.sleep(30)  # check every 30 seconds
