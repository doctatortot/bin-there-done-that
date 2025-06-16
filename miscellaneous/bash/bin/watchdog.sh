#!/bin/bash

# === CONFIG ===
WATCH_STRING="find /mnt/raid5 -type d -exec chmod o+X {} \\;"  # Adjust if needed
CHECK_INTERVAL=60  # seconds
BOT_TOKEN="8178867489:AAH0VjN7VnZSCIWasSz_y97iBLLjPJA751k"
CHAT_ID="1559582356"
HOST=$(hostname)
LOGFILE="$HOME/krang-logs/chmod_watchdog_$(date '+%Y%m%d-%H%M').log"
mkdir -p "$HOME/krang-logs"

# === FIND TARGET PID ===
PID=$(pgrep -f "$WATCH_STRING")

if [ -z "$PID" ]; then
  echo "❌ No matching chmod process found." | tee -a "$LOGFILE"
  exit 1
fi

echo "👁️ Watching PID $PID for chmod job on $HOST..." | tee -a "$LOGFILE"

# === MONITOR LOOP ===
while kill -0 "$PID" 2>/dev/null; do
  echo "⏳ [$HOST] chmod PID $PID still running..." >> "$LOGFILE"
  sleep "$CHECK_INTERVAL"
done

# === COMPLETE ===
MSG="✅ [$HOST] chmod finished on /mnt/raid5
Time: $(date '+%Y-%m-%d %H:%M:%S')
PID: $PID
Watchdog confirmed completion."

echo -e "$MSG" | tee -a "$LOGFILE"

curl -s -X POST https://api.telegram.org/bot$BOT_TOKEN/sendMessage \
  -d chat_id="$CHAT_ID" \
  -d text="$MSG"

