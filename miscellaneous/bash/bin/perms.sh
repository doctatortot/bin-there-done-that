#!/bin/bash
# Safe and resumable chmod script with progress output

TARGET_DIR="/mnt/raid5"
LOGFILE="$HOME/chmod_resume_$(date '+%Y%m%d-%H%M').log"
INTERVAL=500

echo "🔧 Starting permission normalization on $TARGET_DIR"
echo "Logging to $LOGFILE"
echo "Started at $(date)" >> "$LOGFILE"

i=0
find "$TARGET_DIR" -type d -not -perm -005 | while read -r dir; do
  chmod o+X "$dir"
  echo "✔️  $dir" >> "$LOGFILE"
  ((i++))
  if ((i % INTERVAL == 0)); then
    echo "⏳ Processed $i directories so far..."
  fi
done

echo "✅ Completed at $(date)" >> "$LOGFILE"
echo "✅ chmod finished. Total: $i directories."
