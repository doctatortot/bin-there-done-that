#!/bin/bash

# Configuration
TG_BOT_TOKEN="${TG_BOT_TOKEN:7277705363:AAGSw5Pmcbf7IsSyZKMqU6PJ4VsVwdKLRH0}"
TG_CHAT_ID="${TG_CHAT_ID:-1559582356}"

declare -A NODES
NODES=(
  ["genesis-east"]="root@198.74.58.14"
  ["genesis-midwest"]="root@45.56.126.90"
  ["genesis-west"]="root@172.232.172.119"
)

REMOTE_SCRIPT="/root/genesis_routewatch.sh"
CRITICAL=0
OUTPUT=""

send_telegram_alert() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
    -d chat_id="${TG_CHAT_ID}" \
    -d parse_mode="Markdown" \
    -d text="$message" > /dev/null
}

for region in "${!NODES[@]}"; do
  HOST="${NODES[$region]}"
  echo "🌐 Probing $region ($HOST)..."

  OUTPUT_SEGMENT=$(ssh -o ConnectTimeout=10 "$HOST" "bash $REMOTE_SCRIPT" 2>&1)
  OUTPUT+="🛰️ $region Output:\n$OUTPUT_SEGMENT\n\n"

  if echo "$OUTPUT_SEGMENT" | grep -q "Status: CRITICAL"; then
    CRITICAL=1
  fi
done

# Display results
echo -e "$OUTPUT"

if [ $CRITICAL -eq 1 ]; then
  ALERT_MSG="🚨 *GenesisRouteWatch Multi-Region Alert* 🚨\n\n$OUTPUT"
  send_telegram_alert "$ALERT_MSG"
fi
