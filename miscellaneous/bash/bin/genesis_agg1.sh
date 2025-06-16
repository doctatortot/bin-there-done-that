#!/bin/bash

# === Config ===
declare -A NODES=(
  [genesis-west]="root@172.232.172.119"
  [genesis-east]="root@198.74.58.14"
  [genesis-midwest]="root@45.56.126.90"
)

TELEGRAM_BOT_TOKEN="7277705363:AAGSw5Pmcbf7IsSyZKMqU6PJ4VsVwdKLRH0"
TELEGRAM_CHAT_ID="1559582356"

# === Functions ===

send_telegram() {
  local msg="$1"
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="${TELEGRAM_CHAT_ID}" \
    -d text="$msg" \
    -d parse_mode="Markdown"
}

# === Main ===

alert_text="*GenesisRouteWatch Alert!*\n"
issue_found=0

for region in "${!NODES[@]}"; do
  host="${NODES[$region]}"
  echo "🌐 Probing $region ($host)..."
  output=$(ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no $host "/root/genesis_routewatch.sh" 2>/dev/null)
  
  echo "🛰️ $region Output:"
  echo "$output"
  echo

  # Save raw report
  full_report+="🛰️ *$region*:\n\`\`\`\n$output\n\`\`\`\n\n"

  # Detect issues
  if echo "$output" | grep -q "Status: CRITICAL"; then
    alert_text+="$region* path degraded!\n"
    issue_found=1
  fi
done

# Send alert only if something's wrong
if [[ $issue_found -eq 1 ]]; then
  send_telegram "$alert_text"
else
  echo "✅ All paths healthy. No alert sent."
fi
