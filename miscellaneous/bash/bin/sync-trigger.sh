#!/bin/bash

# === CONFIG ===
REMOTE_HOST="shredder.sshjunkie.com"
REMOTE_USER="doc"
REMOTE_SCRIPT="/home/doc/sync.sh"
LOG_TAG="[Krang → SPL Sync]"

# === Mastodon Alert Settings ===
MASTODON_INSTANCE="https://chatwithus.live"
ACCESS_TOKEN="07w3Emdw-cv_TncysrNU8Ed_sHJhwtnvKmnLqKlHmKA"
TOOT_VISIBILITY="public"

# === Telegram Settings ===
TELEGRAM_BOT_TOKEN="8178867489:AAH0VjN7VnZSCIWasSz_y97iBLLjPJA751k"
TELEGRAM_CHAT_ID="1559582356"

# === Execution ===
echo "$LOG_TAG Triggering remote sync..."
OUTPUT=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "${REMOTE_SCRIPT}" 2>&1)

if echo "$OUTPUT" | grep -q "All syncs finished"; then
    echo "$LOG_TAG ✅ Sync complete."

    # Mastodon alert
    curl -s -X POST "$MASTODON_INSTANCE/api/v1/statuses" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -d "status=✅ SPL Sync completed successfully via Krang" \
      -d "visibility=$TOOT_VISIBILITY" >/dev/null

    # Telegram alert
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
      -d "chat_id=$TELEGRAM_CHAT_ID" \
      -d "text=✅ SPL Sync completed successfully from Krang." >/dev/null
else
    echo "$LOG_TAG ❌ Sync may have failed. Check logs."

    # Failure alerts
    curl -s -X POST "$MASTODON_INSTANCE/api/v1/statuses" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -d "status=❌ SPL Sync failed from Krang. Check logs." \
      -d "visibility=$TOOT_VISIBILITY" >/dev/null

    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
      -d "chat_id=$TELEGRAM_CHAT_ID" \
      -d "text=❌ SPL Sync failed from Krang. Manual check needed." >/dev/null
fi

