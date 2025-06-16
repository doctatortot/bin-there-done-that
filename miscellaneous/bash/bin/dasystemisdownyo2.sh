#!/bin/bash
# da system is down yo – Krang Healthcheck
# Monitors system health across all Genesis nodes

# === CONFIG ===
REMOTE_USER="doc"
BOT_TOKEN="7277705363:AAGSw5Pmcbf7IsSyZKMqU6PJ4VsVwdKLRH0"
CHAT_ID="1559582356"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOGFILE="$HOME/krang-logs/health-$(date '+%Y%m%d-%H%M').log"

SWAP_LIMIT_MB=512
LOAD_LIMIT=4.0
mkdir -p "$HOME/krang-logs"

# === Host list ===
SERVERS=(
  zcluster.technodrome1.sshjunkie.com
  zcluster.technodrome2.sshjunkie.com
  shredder.sshjunkie.com
  chatwithus.live
  portal.genesishostingtechnologies.com
)

# === Roles per host ===
declare -A HOST_ROLES=(
  [zcluster.technodrome1]="postgres"
  [zcluster.technodrome2]="postgres"
  [shredder]="minio"
  [chatwithus]="mastodon docker nginx"
  [portal]="azuracast docker nginx"
)

SUMMARY="📡 Krang System Health Report - $TIMESTAMP

"

for HOST in "${SERVERS[@]}"; do
  SHORT_HOST=$(echo "$HOST" | cut -d'.' -f1)
  echo "🔍 Collecting from $HOST..."

  DATA=$(ssh "$REMOTE_USER@$HOST" bash -s << 'EOF'
set -e
HOST=$(hostname)
MEM=$(awk '/MemAvailable/ {printf "%.1f Gi free", $2 / 1024 / 1024}' /proc/meminfo)
SWAP_RAW=$(free -m | awk '/Swap:/ {print $3}')
SWAP="$SWAP_RAW Mi used"
DISK=$(df -h / | awk 'NR==2 {print $4 " free"}')
LOAD=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | xargs)
UPTIME=$(uptime -p)

# Graceful service status checks
check_status() {
  systemctl is-active "$1" 2>/dev/null || echo "inactive"
}
NGINX=$(check_status nginx)
DOCKER=$(check_status docker)
PGSQL=$(check_status postgresql)

echo "$HOST|$MEM|$SWAP_RAW|$SWAP|$DISK|$LOAD|$UPTIME|$NGINX|$DOCKER|$PGSQL"
EOF
) || {
  SUMMARY+="🖥️ $HOST
❌ Failed to connect or run checks.
"
  continue
}

  IFS='|' read -r H MEM SWAP_MB SWAP_HUMAN DISK LOAD1 UPTIME_STATUS NGINX_STATUS DOCKER_STATUS PGSQL_STATUS <<< "$DATA"
  ROLES="${HOST_ROLES[$SHORT_HOST]}"
  ALERTS=""

  # === Smart Swap Alert: only if memory is low OR system is under load ===
  if [[ -n "$SWAP_MB" && "$SWAP_MB" =~ ^[0-9]+$ && "$SWAP_MB" -gt "$SWAP_LIMIT_MB" ]]; then
    MEM_MB=$(echo "$MEM" | awk '{printf "%d", $1 * 1024}' 2>/dev/null)
    LOAD_HIGH=$(awk "BEGIN {print ($LOAD1 > $LOAD_LIMIT) ? 1 : 0}")
    if [[ "$MEM_MB" -lt 1024 || "$LOAD_HIGH" -eq 1 ]]; then
      ALERTS+="⚠️ HIGH SWAP ($SWAP_HUMAN)\n"
    fi
  fi

  # === Load Alert ===
  if [[ -n "$LOAD1" ]]; then
    LOAD_HIGH=$(awk "BEGIN {print ($LOAD1 > $LOAD_LIMIT) ? 1 : 0}")
    [ "$LOAD_HIGH" -eq 1 ] && ALERTS+="⚠️ HIGH LOAD ($LOAD1)\n"
  fi

  # === Service Status Checks ===
  [[ "$ROLES" == *"nginx"* && "$NGINX_STATUS" != "active" ]] && ALERTS+="❌ NGINX not running\n"
  if [[ "$ROLES" == *"docker"* && "$SHORT_HOST" != "shredder" && "$DOCKER_STATUS" != "active" ]]; then
    ALERTS+="❌ Docker not running\n"
  fi
  [[ "$ROLES" == *"postgres"* && "$PGSQL_STATUS" != "active" ]] && ALERTS+="❌ PostgreSQL not running\n"

  ALERTS_MSG=""
  [ -n "$ALERTS" ] && ALERTS_MSG="🚨 ALERTS:
$ALERTS"

  SUMMARY+="🖥️ $H
• Mem: $MEM
• Swap: $SWAP_HUMAN
• Disk: $DISK
• Load: ${LOAD1:-Unavailable}
• Uptime: $UPTIME_STATUS
• Roles: ${ROLES:-none}
$ALERTS_MSG
"
done

# === Krang Clock Sync Check ===
NTP_RESULT=$(ntpdate -q time.google.com 2>&1)
OFFSET=$(echo "$NTP_RESULT" | awk '/offset/ {print $10}')
if [[ "$OFFSET" =~ ^-?[0-9.]+$ ]]; then
  OFFSET_MS=$(awk "BEGIN {printf \"%.0f\", $OFFSET * 1000}")
  if (( OFFSET_MS > 500 || OFFSET_MS < -500 )); then
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

# === Log & Send ===
echo -e "$SUMMARY" > "$LOGFILE"

curl -s -X POST https://api.telegram.org/bot$BOT_TOKEN/sendMessage \
     -d chat_id="$CHAT_ID" \
     -d text="$SUMMARY"
