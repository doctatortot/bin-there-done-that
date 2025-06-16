#!/bin/bash

STAMP=$(date +%Y%m%d-%H%M%S)
VAULT_HOST="root@thevault.sshjunkie.com"
TG_BOT_TOKEN="8178867489:AAH0VjN7VnZSCIWasSz_y97iBLLjPJA751k"
TG_CHAT_ID="1559582356"
TG_API="https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage"

# Source directories to back up
SOURCE_DIRS=(
    "/home/doc/genesis-tools/"

)

# Destination directories on the vault
DEST_DIRS=(
    "/nexus/krang_assets"

)

# Rsync commands to back up directories
for i in "${!SOURCE_DIRS[@]}"; do
    # Rsync to the vault (using SSH)
    rsync -avz --delete "${SOURCE_DIRS[$i]}" "$VAULT_HOST:${DEST_DIRS[$i]}$STAMP/"

    # Check if the rsync was successful and send a Telegram message
    if [ $? -eq 0 ]; then
        curl -s -X POST "$TG_API" -d chat_id="$TG_CHAT_ID" -d text="📦 Krang backup complete for ${SOURCE_DIRS[$i]} → ${DEST_DIRS[$i]}$STAMP"
    else
        curl -s -X POST "$TG_API" -d chat_id="$TG_CHAT_ID" -d text="⚠️ Krang backup failed for ${SOURCE_DIRS[$i]} → ${DEST_DIRS[$i]}$STAMP"
    fi
done
