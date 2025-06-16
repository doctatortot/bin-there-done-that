#!/bin/bash
# This script finds and blows away directory landmines in a MinIO-mounted filesystem
# where files are supposed to go but directories already exist. Use with caution.

LOG="/tmp/minio_detonation.log"
ERROR_LOG="/tmp/rclonemasto-dump.log"
TARGET_BASE="/assets/minio-data/mastodon"

echo "[*] Scanning for blocking directories... 💣" | tee "$LOG"

grep 'is a directory' "$ERROR_LOG" | \
awk -F': open ' '{print $2}' | \
sed 's/: is a directory//' | \
sort -u | while read -r bad_path; do
    if [ -d "$bad_path" ]; then
        echo "[💥] Nuking: $bad_path" | tee -a "$LOG"
        rm -rf "$bad_path"
    else
        echo "[✔️] Skipped (not a dir): $bad_path" | tee -a "$LOG"
    fi
done

echo "[✅] All blocking directories removed. Re-run rclone and finish the war." | tee -a "$LOG"
