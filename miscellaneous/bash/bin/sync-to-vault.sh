#!/bin/bash

# === CONFIG ===
SRC_HOST="shredderv1"
SRC_BASE="/mnt/raid5/minio-data"
DEST_HOST="root@thevault@sshjunkie.com"
LOG="/home/doc/genesis-tools/vault_sync.log"
TG_TOKEN="8178867489:AAH0VjN7VnZSCIWasSz_y97iBLLjPJA751k"
TG_CHAT_ID="1559582356"

declare -A BUCKETS_TO_DATASETS=(
  [genesisassets]="nexus/genesisassets-secure"
  [genesislibrary]="nexus/genesislibrary-secure"
  [assets_archives]="nexus/genesisarchives-secure"
  [assets_mastodon]="nexus/assets_mastodon"
  [assets_azuracast]="nexus/assets_azuracast"
)

echo "[$(date)] 🔁 Starting MinIO-to-Vault sync job..." >> "$LOG"

for bucket in "${!BUCKETS_TO_DATASETS[@]}"; do
  src="${SRC_HOST}:${SRC_BASE}/${bucket}/"
  dest="${BUCKETS_TO_DATASETS[$bucket]}/"

  echo "[*] Syncing $bucket → $dest" >> "$LOG"
  rsync -aHAXv --delete "$src" "$DEST_HOST:$dest" >> "$LOG" 2>&1

  curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
       -d chat_id="$TG_CHAT_ID" \
       -d text="✅ Sync complete: $bucket → ${BUCKETS_TO_DATASETS[$bucket]}"
done

echo "[$(date)] ✅ All MinIO buckets synced to The Vault." >> "$LOG"
