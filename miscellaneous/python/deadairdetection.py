#!/usr/bin/env python3

import subprocess
import time
import os
import requests
from datetime import datetime

# --- CONFIG ---
STREAM_URL = "http://stream.genesis-radio.net:7454/stream"
DURATION = 30  # Seconds to monitor
SILENCE_THRESHOLD = "-50dB"
SILENCE_DURATION = 5  # Seconds of continuous silence to trigger alert

TELEGRAM_BOT_TOKEN = "8178867489:AAH0VjN7VnZSCIWasSz_y97iBLLjPJA751k"
TELEGRAM_CHAT_ID = "1559582356"

ALERT_FLAG_PATH = "/tmp/genesis_radio_silence.alerted"

# --- FUNCTIONS ---

def check_for_silence():
    """Run ffmpeg with silencedetect and return True if silence is detected."""
    command = [
        "ffmpeg",
        "-i", STREAM_URL,
        "-t", str(DURATION),
        "-af", f"silencedetect=noise={SILENCE_THRESHOLD}:d={SILENCE_DURATION}",
        "-f", "null", "-"
    ]

    try:
        output = subprocess.check_output(command, stderr=subprocess.STDOUT, text=True)
        return "silence_start" in output
    except subprocess.CalledProcessError as e:
        return "silence_start" in e.output

def send_telegram_alert():
    """Send an alert to Telegram."""
    message = f"🚨 Genesis Radio Alert [{datetime.now()}]: Possible dead air detected on the stream."
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    payload = {
        "chat_id": TELEGRAM_CHAT_ID,
        "text": message
    }
    try:
        requests.post(url, data=payload, timeout=10)
    except requests.RequestException as e:
        print(f"[!] Failed to send Telegram alert: {e}")

def main():
    silence = check_for_silence()
    if silence:
        if not os.path.exists(ALERT_FLAG_PATH):
            send_telegram_alert()
            open(ALERT_FLAG_PATH, "w").close()
    else:
        if os.path.exists(ALERT_FLAG_PATH):
            os.remove(ALERT_FLAG_PATH)

if __name__ == "__main__":
    main()
