import random
import time
import requests

# === CONFIG ===
MASTODON_INSTANCE = "https://chatwithus.live"  # e.g., https://chatwithus.live
ACCESS_TOKEN = "rimxBLi-eaJAcwagkmoj6UoW7Lc473tQY0cOM041Euw"

MIN_WAIT = 10             # minimum seconds to wait between posts (e.g., 10)
MAX_WAIT = 3 * 60 * 60    # maximum seconds to wait (e.g., 3 hours)

def random_buu():
    n = random.randint(2, 12)
    return "AH " + " ".join(["BUU"] * n)

def toot_buu():
    msg = random_buu()
    print("Tooting:", msg)
    url = f"{MASTODON_INSTANCE}/api/v1/statuses"
    headers = {"Authorization": f"Bearer {ACCESS_TOKEN}"}
    payload = {"status": msg}
    resp = requests.post(url, headers=headers, data=payload)
    if resp.status_code == 200:
        print("Success!")
    else:
        print(f"Failed: {resp.status_code} {resp.text}")

def main():
    while True:
        wait_time = random.randint(MIN_WAIT, MAX_WAIT)
        print(f"Waiting {wait_time} seconds until next BUU...")
        time.sleep(wait_time)
        toot_buu()

if __name__ == "__main__":
    main()

