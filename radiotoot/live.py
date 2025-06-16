import requests
import time
from mastodon import Mastodon

# === Config ===
MASTODON_BASE_URL = "https://chatwithus.live"
MASTODON_ACCESS_TOKEN = "07w3Emdw-cv_TncysrNU8Ed_sHJhwtnvKmnLqKlHmKA"
ICECAST_STATUS_URL = "http://cast3.my-control-panel.com:7454/status-json.xsl"
LIVE_MOUNTPOINT = "/live"
CHECK_INTERVAL = 30  # seconds
LIVE_MIN_INTERVAL = 600  # 10 minutes

mastodon = Mastodon(
    access_token=MASTODON_ACCESS_TOKEN,
    api_base_url=MASTODON_BASE_URL
)

last_title_posted = None
last_post_time = 0

def get_live_stream_title():
    try:
        r = requests.get(ICECAST_STATUS_URL, timeout=5)
        r.raise_for_status()
        data = r.json()
        sources = data.get("icestats", {}).get("source", [])

        if isinstance(sources, dict):
            sources = [sources]

        for source in sources:
            listenurl = source.get("listenurl", "")
            title = source.get("title") or source.get("server_name")
            title = title.strip() if title else None
            listeners = int(source.get("listeners", 0))

            print(f"[DEBUG] {listenurl=} {title=} {listeners=}")  # Keep for troubleshooting

            if LIVE_MOUNTPOINT in listenurl and title and listeners > 0:
                return title
    except Exception as e:
        print(f"[ERROR] Icecast fetch failed: {e}")
    return None

def main():
    global last_title_posted, last_post_time
    print("🎙️ Watching /live only. Toots only when DJs are on deck.")

    while True:
        now = time.time()
        title = get_live_stream_title()

        if title and title != last_title_posted and (now - last_post_time) > LIVE_MIN_INTERVAL:
            toot_msg = f"🔴 Live now on Genesis Radio: {title}! Tune in: http://stream.genesis-radio.net:7454/stream"
            try:
                mastodon.status_post(toot_msg, visibility='public')
                print(f"[TOOTED] {toot_msg}")
                last_title_posted = title
                last_post_time = now
            except Exception as e:
                print(f"[ERROR] Mastodon post failed: {e}")
        else:
            print("🔍 No new live DJ activity.")

        time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    main()
