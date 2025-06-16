#!/bin/bash

# === CONFIG ===
REMOTE_USER="doc"
BOT_TOKEN="8178867489:AAH0VjN7VnZSCIWasSz_y97iBLLjPJA751k"
CHAT_ID="1559582356"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOGFILE="$HOME/krang-logs/health-$(date '+%Y%m%d-%H%M').log"

# Thresholds
SWAP_LIMIT_MB=512
LOAD_LIMIT=4.0

mkdir -p "$HOME/krang-logs"

SERVERS=(
  thevault.sshjunkie.com
  zcluster.technodrome1.sshjunkie.com
  zcluster.technodrome2.sshjunkie.com
  shredder.sshjunkie.com
  chatwithus.live
)

SUMMARY="📡 Krang System Health Report - $TIMESTAMP

"

for HOST in "${SERVERS[@]}"; do
  echo "🔍 Collecting from $HOST..."

  DATA=$(ssh "$REMOTE_USER@$HOST" bash -s << 'EOF'
HOST=$(hostname)
MEM=$(awk '/MemAvailable/ {printf "%.1f Gi free", $2 / 1024 / 1024}' /proc/meminfo)
SWAP_RAW=$(free -m | awk '/Swap:/ {print $3}')
SWAP="$SWAP_RAW Mi used"
DISK=$(df -h / | awk 'NR==2 {print $4 " free"}')
LOAD=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | xargs)
UPTIME=$(uptime -p)

# Optional service checks
NGINX=$(systemctl is-active nginx 2>/dev/null)
DOCKER=$(systemctl is-active docker 2>/dev/null)
PGSQL=$(systemctl is-active postgresql 2>/dev/null || systemctl is-active postgresql@14-main 2>/dev/null)

echo "$HOST|$MEM|$SWAP_RAW|$SWAP|$DISK|$LOAD|$UPTIME|$NGINX|$DOCKER|$PGSQL"
EOF
)

  IFS='|' read -r H MEM SWAP_MB SWAP_HUMAN DISK LOAD1 UPTIME_STATUS NGINX_STATUS DOCKER_STATUS PGSQL_STATUS <<< "$DATA"

  ALERTS=""
  if (( SWAP_MB > SWAP_LIMIT_MB )); then
    ALERTS+="⚠️ HIGH SWAP ($SWAP_HUMAN)
"
  fi

  LOAD_INT=$(awk "BEGIN {print ($LOAD1 > $LOAD_LIMIT) ? 1 : 0}")
  if [ "$LOAD_INT" -eq 1 ]; then
    ALERTS+="⚠️ HIGH LOAD ($LOAD1)
"
  fi

  [ "$NGINX_STATUS" != "active" ] && ALERTS+="❌ NGINX not running
"
  [ "$DOCKER_STATUS" != "active" ] && ALERTS+="❌ Docker not running
"
  [ "$PGSQL_STATUS" != "active" ] && ALERTS+="❌ PostgreSQL not running
"

  ALERTS_MSG=""
  [ -n "$ALERTS" ] && ALERTS_MSG="🚨 ALERTS:
$ALERTS"

  SUMMARY+="🖥️ $H
• Mem: $MEM
• Swap: $SWAP_HUMAN
• Disk: $DISK
• Load: $LOAD1
• Uptime: $UPTIME_STATUS
$ALERTS_MSG
"
done

# === KRANG CLOCK ACCURACY CHECK ===
NTP_RESULT=$(ntpdate -q time.google.com 2>&1)
OFFSET=$(echo "$NTP_RESULT" | awk '/offset/ {print $10}')
OFFSET_MS=$(awk "BEGIN {printf "%.0f", $OFFSET * 1000}")

if [[ -n "$OFFSET_MS" ]]; then
  if (( OFFSET_MS > 500 || OFFSET_MS < -500 )); then
    # Auto-correct the system clock
    CORRECTION=$(ntpdate -u time.google.com 2>&1)
    SUMMARY+="🛠️ Auto-corrected Krang clock via ntpdate: $CORRECTION
"
    SUMMARY+="🕰️ Krang Clock Offset: ${OFFSET_MS}ms — ⚠️ OUT OF SYNC
"
  else
    SUMMARY+="🕰️ Krang Clock Offset: ${OFFSET_MS}ms — ✅ SYNCHRONIZED
"
  fi
else
  SUMMARY+="🕰️ Krang Clock Check: ❌ FAILED to retrieve offset.
"
fi

# Log to file
echo -e "$SUMMARY" > "$LOGFILE"

# Send to Telegram
curl -s -X POST https://api.telegram.org/bot$BOT_TOKEN/sendMessage \
     -d chat_id="$CHAT_ID" \
     -d text="$SUMMARY"
