#!/bin/bash

# === CONFIG ===
SCRIPT_PATH="/usr/local/bin/do_the_needful.sh"
REMOTE_USER="doc"
BOT_TOKEN="8178867489:AAH0VjN7VnZSCIWasSz_y97iBLLjPJA751k"
CHAT_ID="1559582356"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

SERVERS=(
  thevault.sshjunkie.com
  zcluster.technodrome1.sshjunkie.com
  zcluster.technodrome2.sshjunkie.com
  shredder.sshjunkie.com
  chatwithus.live
)

SUMMARY="🤖 Krang Deployment Report - $TIMESTAMP\n\n"
FAILURES=0

for HOST in "${SERVERS[@]}"; do
  echo "🚀 Deploying to $HOST..."

  # Upload script to temp location
  scp "$SCRIPT_PATH" "$REMOTE_USER@$HOST:/tmp/do_the_needful.sh"
  if [ $? -ne 0 ]; then
    SUMMARY+="❌ $HOST: SCP failed\n"
    ((FAILURES++))
    continue
  fi

  # Move into place and execute
  ssh "$REMOTE_USER@$HOST" "sudo install -m 755 /tmp/do_the_needful.sh $SCRIPT_PATH && sudo $SCRIPT_PATH"
  if [ $? -ne 0 ]; then
    SUMMARY+="❌ $HOST: sudo execution failed\n"
    ((FAILURES++))
  else
    SUMMARY+="✅ $HOST: cleaned successfully\n"
  fi

  echo "----------------------------------"
done

# === Send Telegram Summary ===
FINAL_STATUS="🚨 Some hosts failed." && [ "$FAILURES" -eq 0 ] && FINAL_STATUS="✅ All hosts completed."

curl -s -X POST https://api.telegram.org/bot$BOT_TOKEN/sendMessage \
  -d chat_id="$CHAT_ID" \
  -d text="$FINAL_STATUS\n\n$SUMMARY"
