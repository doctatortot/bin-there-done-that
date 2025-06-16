#!/bin/bash

# === CONFIG ===
ZFS_MOUNT="/assets"
LINODE_ALIAS="linode"
KRANG_BOT_TOKEN="your-bot-token-here"
CHAT_ID="your-chat-id-here"
MINIO_SERVICE="minio"
LOG_DIR="/home/doc/genesisdr"  # <- customize this!

# === SETUP ===
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
LOG_FILE="$LOG_DIR/mirror_$TIMESTAMP.log"

# === START LOGGING ===
exec > >(tee -a "$LOG_FILE") 2>&1

echo "🔐 Genesis DR MinIO Mirror Log — $TIMESTAMP"
echo "Log file: $LOG_FILE"
echo "Starting DR mirror from $ZFS_MOUNT to $LINODE_ALIAS"
echo "-------------------------------------------"

# === SYNC ===
mc mirror --overwrite "$ZFS_MOUNT" "$LINODE_ALIAS" --quiet
MIRROR_STATUS=$?

if [[ $MIRROR_STATUS -ne 0 ]]; then
  echo "❌ Mirror failed with exit code $MIRROR_STATUS"
  curl -s -X POST https://api.telegram.org/bot$KRANG_BOT_TOKEN/sendMessage \
       -d chat_id="$CHAT_ID" \
       -d text="❌ MinIO DR mirror to Linode FAILED. MinIO remains offline. Log: $LOG_FILE"
  exit 1
fi

echo "✅ Mirror complete. Starting MinIO..."
systemctl start "$MINIO_SERVICE"

curl -s -X POST https://api.telegram.org/bot$KRANG_BOT_TOKEN/sendMessage \
     -d chat_id="$CHAT_ID" \
     -d text="✅ MinIO DR mirror to Linode completed successfully. MinIO is online. Log: $LOG_FILE"

echo "🚀 All done."
echo "-------------------------------------------"
