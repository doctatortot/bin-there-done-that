#!/bin/bash
# GenesisSync Progress Tracker - No hangs, no nonsense

SOURCE="/mnt/raid5/minio-data/linodeassets"
DEST="/assets/minio-data/mastodon"
LOG="/root/genesis_sync_progress.log"
INTERVAL=300  # in seconds

mkdir -p $(dirname "$LOG")

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    SRC_COUNT=$(rclone size "$SOURCE" --json | jq .objects)
    DST_COUNT=$(rclone size "$DEST" --json | jq .objects)

    if [[ -z "$SRC_COUNT" || -z "$DST_COUNT" ]]; then
        echo "[$TIMESTAMP] Error getting file counts. Retrying in $INTERVAL seconds..." | tee -a "$LOG"
    else
        PERCENT=$(( DST_COUNT * 100 / SRC_COUNT ))
        echo "[$TIMESTAMP] Synced: $DST_COUNT / $SRC_COUNT ($PERCENT%)" | tee -a "$LOG"
    fi

    sleep $INTERVAL
done
