#!/bin/bash

# FailZero Early Warning System (FZ EWS)
# Monitor critical hosts and alert on Telegram on failure

# === INSERT YOUR TELEGRAM CREDENTIALS BELOW ===
BOT_TOKEN="8031184325:AAEGj3gzwYF8HaLjWHVe0gOG5bzo63tcRbU"
CHAT_ID="1559582356"

# === INSERT YOUR CRITICAL HOSTNAMES BELOW ===
CRITICAL_HOSTS=(
  "da.genesishostingtechnologies.com"
  "zcluster.technodrome1.sshjunkie.com"
  "zcluster.technodrome2.sshjunkie.com"
  "krang.core.sshjunkie.com"
  "tt.themediahub.org"
  "toot.themediahub.org"
  "chatwithus.live"
  "genesishostingtechnologies.com"
  "portal.genesishostingtechnologies.com"
  "brandoncharles.us"
  # Add more hostnames here, one per line inside quotes
)

LOG_FILE="/home/doc/fz_ews.log"
COOLDOWN_FILE="/home/doc/fz_ews_cooldown"

# Cooldown period in seconds to prevent alert spam (e.g., 3600 = 1 hour)
ALERT_COOLDOWN=3600

send_telegram_alert() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
       -d chat_id="$CHAT_ID" \
       -d text="🚨 FailZero EWS Alert: $message" > /dev/null
}

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

check_cooldown() {
  local host="$1"
  local now=$(date +%s)
  local last_alert=$(grep "^$host " "$COOLDOWN_FILE" 2>/dev/null | awk '{print $2}')
  if [[ -z "$last_alert" ]]; then
    return 0
  fi
  local elapsed=$((now - last_alert))
  if (( elapsed > ALERT_COOLDOWN )); then
    return 0
  else
    return 1
  fi
}

update_cooldown() {
  local host="$1"
  local now=$(date +%s)
  # Remove existing entry for host if any
  grep -v "^$host " "$COOLDOWN_FILE" 2>/dev/null > "${COOLDOWN_FILE}.tmp"
  mv "${COOLDOWN_FILE}.tmp" "$COOLDOWN_FILE"
  # Append new timestamp
  echo "$host $now" >> "$COOLDOWN_FILE"
}

check_host() {
  local host="$1"
  if ping -c 2 -W 3 "$host" > /dev/null 2>&1; then
    log "$host is UP"
  else
    log "$host is DOWN"
    if check_cooldown "$host"; then
      send_telegram_alert "$host is DOWN or unreachable!"
      update_cooldown "$host"
    else
      log "Cooldown active for $host; alert suppressed"
    fi
  fi
}

main() {
  for host in "${CRITICAL_HOSTS[@]}"; do
    check_host "$host"
  done
}

main
