#!/bin/bash

SRC_BASE="/mnt/convert/archives"
DEST_BASE="/mnt/5tb/archives"
RETENTION_MONTHS=3
TODAY=$(date +%s)

LOG_FILE="/var/log/archive_retention.log"

# Log start of run
echo "=== Archive Sync: $(date) ===" >> "$LOG_FILE"

# Init counters
files_checked=0
files_archived=0
files_deleted=0

# Traverse all subfolders
find "$SRC_BASE" -type f -name '*.mp3' | while read -r file; do
    ((files_checked++))

    filename=$(basename "$file")
    relative_path=$(realpath --relative-to="$SRC_BASE" "$file")
    subfolder=$(dirname "$relative_path")
    dest_folder="$DEST_BASE/$subfolder"
    dest_file="$dest_folder/$filename"

    # --- Date extraction logic (supports YYYY-MM-DD or YYYYMMDD) ---
    file_date=$(echo "$filename" | grep -oP '\d{4}-\d{2}-\d{2}')

    if [ -z "$file_date" ]; then
        raw_date=$(echo "$filename" | grep -oP '\d{8}')
        if [ ! -z "$raw_date" ]; then
            file_date="${raw_date:0:4}-${raw_date:4:2}-${raw_date:6:2}"
        fi
    fi

    if [ -z "$file_date" ]; then
        echo "Skipping (no valid date found): $filename" >> "$LOG_FILE"
        continue
    fi

    file_epoch=$(date -d "$file_date" +%s 2>/dev/null)
    if [ -z "$file_epoch" ]; then
        echo "Skipping (invalid date format): $filename" >> "$LOG_FILE"
        continue
    fi

    age_months=$(( (TODAY - file_epoch) / 2592000 ))

    # Make sure destination folder exists
    mkdir -p "$dest_folder"

    if [ "$age_months" -le "$RETENTION_MONTHS" ]; then
        if [ ! -f "$dest_file" ]; then
            echo "Archiving: $filename → $dest_folder" >> "$LOG_FILE"
            cp "$file" "$dest_file"
            ((files_archived++))
        fi
    else
        if [ -f "$dest_file" ]; then
            echo "Deleting expired: $filename" >> "$LOG_FILE"
            rm "$dest_file"
            ((files_deleted++))
        fi
    fi
done

# Final summary log
echo "Checked: $files_checked | Archived: $files_archived | Deleted: $files_deleted" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
