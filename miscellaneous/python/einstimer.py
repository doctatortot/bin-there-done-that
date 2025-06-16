#!/usr/bin/env python3

import os
import subprocess
import hashlib
import time
from datetime import datetime
import requests

# === Configuration ===
DEST_USER = "doc"
DEST_HOST = "chatwithus.live"
DEST_PATH = f"/home/{DEST_USER}/genesis_timer/"
DEST_FULL = f"{DEST_USER}@{DEST_HOST}"
LOCAL_TESTFILE = f"/home/{DEST_USER}/genesis_testfile_10mb"
REMOTE_TESTFILE = f"{DEST_PATH}genesis_testfile_10mb"
LOGFILE = f"/home/{DEST_USER}/genesis_timer.log"

# Mastodon alert config
MASTODON_INSTANCE = "https://chatwithus.live"
MASTODON_TOKEN = "rimxBLi-eaJAcwagkmoj6UoW7Lc473tQY0cOM041Euw"  # Replace with real token
ALERT_THRESHOLD_MS = 2000  # Alert if transfer takes longer than this

# === Helpers ===

def create_test_file(path):
    if not os.path.exists(path):
        with open(path, "wb") as f:
            f.write(os.urandom(10 * 1024 * 1024))

def sha256sum(filename):
    h = hashlib.sha256()
    with open(filename, 'rb') as f:
        while chunk := f.read(8192):
            h.update(chunk)
    return h.hexdigest()

def send_masto_alert(message):
    headers = {
        "Authorization": f"Bearer {MASTODON_TOKEN}"
    }
    payload = {
        "status": message,
        "visibility": "unlisted"
    }
    try:
        r = requests.post(f"{MASTODON_INSTANCE}/api/v1/statuses", headers=headers, data=payload)
        r.raise_for_status()
    except Exception as e:
        print(f"[{datetime.now()}] Mastodon alert failed: {e}")

# === Core Function ===

def run_transfer():
    create_test_file(LOCAL_TESTFILE)
    local_hash = sha256sum(LOCAL_TESTFILE)

    # Ensure remote directory exists
    subprocess.run(
        ["ssh", DEST_FULL, f"mkdir -p {DEST_PATH}"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )

    # Start transfer
    start = time.time()
    try:
        subprocess.run(
            ["scp", LOCAL_TESTFILE, f"{DEST_FULL}:{DEST_PATH}"],
            check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
    except subprocess.CalledProcessError as e:
        error_msg = f"[{datetime.now()}] Transfer failed: {e.stderr.decode()}"
        send_masto_alert("🚨 GenesisTimer Alert: Transfer failed.")
        return error_msg

    end = time.time()
    duration_ms = int((end - start) * 1000)

    # Check hash remotely
    try:
        result = subprocess.run(
            ["ssh", DEST_FULL, f"sha256sum {REMOTE_TESTFILE}"],
            check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        remote_hash = result.stdout.decode().split()[0]
    except subprocess.CalledProcessError as e:
        error_msg = f"[{datetime.now()}] Remote hash check failed: {e.stderr.decode()}"
        send_masto_alert("🚨 GenesisTimer Alert: Remote hash check failed.")
        return error_msg

    # Cleanup
    subprocess.run(["ssh", DEST_FULL, f"rm -f {REMOTE_TESTFILE}"])
    if os.path.exists(LOCAL_TESTFILE):
        os.remove(LOCAL_TESTFILE)

    match = "MATCH" if remote_hash == local_hash else "MISMATCH"

    log_entry = (
        f"[{datetime.now()}] Transfer to {DEST_FULL} took {duration_ms} ms | "
        f"SHA256: {match}\n"
    )

    with open(LOGFILE, "a") as log:
        log.write(log_entry)

    # 🚨 Alert if needed
    if match != "MATCH" or duration_ms > ALERT_THRESHOLD_MS:
        alert_msg = (
            f"🚨 GenesisTimer Alert:\n"
            f"Transfer to {DEST_HOST} took {duration_ms} ms\n"
            f"Hash check: {match}"
        )
        send_masto_alert(alert_msg)

    return log_entry

# === Run ===
if __name__ == "__main__":
    print(run_transfer())
