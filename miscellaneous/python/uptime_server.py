from flask import Flask, jsonify
import os
import json
from datetime import datetime, timedelta

app = Flask(__name__)

LOG_DIR = "/var/log/genesis_uptime"
CHECK_WINDOW_HOURS = 24

SERVICES = {
    "radio": "https://genesis-radio.net",
    "mastodon": "https://chatwithus.live",
    "minio": "https://console.sshjunkie.com",
    "azura": "https://portal.genesishostingtechnologies.com",
    "teamtalk": "http://tt.themediahub.org",
    "directadmin": "https://da.genesishostingtechnologies.com"
}

@app.route("/api/uptime/<service>")
def get_uptime(service):
    log_path = os.path.join(LOG_DIR, f"{service}.log")
    if not os.path.exists(log_path):
        return jsonify({"uptime": "n/a"}), 404

    now = datetime.utcnow()
    window_start = now - timedelta(hours=CHECK_WINDOW_HOURS)

    total = 0
    up = 0

    with open(log_path, "r") as f:
        for line in f:
            try:
                timestamp_str, status = line.strip().split(",")
                timestamp = datetime.strptime(timestamp_str, "%Y-%m-%dT%H:%M:%S")
                if timestamp >= window_start:
                    total += 1
                    if status == "up":
                        up += 1
            except Exception:
                continue

    uptime_percent = round((up / total) * 100, 2) if total > 0 else 0.0
    return jsonify({"uptime": uptime_percent})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
