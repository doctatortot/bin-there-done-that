#!/usr/bin/env bash
#set -e
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
# === Enable Full Debug Logging ===
exec >> /home/doc/healthchecks/watchman.log 2>&1
set -x  # Print each command as it’s run
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
echo "[$DATE] Watchman script executed" >> /var/log/watchman_cron.log

# === Config ===
PRIMARY_IP="38.102.127.168"           # Main TeamTalk server
BACKUP_IP="172.238.63.162"            # Backup TeamTalk server
CF_ZONE_ID="c5099d42caa2d9763227267c597cb758"
CF_RECORD_ID="7001484a25f0fe5c323845b6695f7544"
CF_API_TOKEN="lCz1kH6nBZPJL0EWrNI-xEDwfR0oOLpg05fq6M81"
THRESHOLD_LATENCY=150
THRESHOLD_LOSS=5
BOT_TOKEN="123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
CHAT_ID="987654321"
DNS_NAME="tt.themediahub.org"

LOG_FILE="/home/doc/healthchecks/watchman.log"
DATE="$(date '+%Y-%m-%d %H:%M:%S')"

# === Current DNS IP ===
CURRENT_IP=$(/usr/bin/dig +short "$DNS_NAME" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
echo "[$DATE] Current IP: $CURRENT_IP"
# === Check Primary Server Health ===
echo "[$DATE] 🔎 Checking ping to $PRIMARY_IP..."
PING_OUTPUT=$(/bin/ping -c 4 "$PRIMARY_IP" || echo "Ping failed")
LATENCY=$(echo "$PING_OUTPUT" | tail -1 | /usr/bin/awk -F '/' '{print $5}')
echo "[$DATE] Ping output: $PING_OUTPUT"
LOSS=$(echo "$PING_OUTPUT" | /bin/grep -oP '\d+(?=% packet loss)')
echo "[$DATE] Parsed latency: $LATENCY, loss: $LOSS"
echo "[$DATE] Ping output: $PING_OUTPUT"
echo "[$DATE] Parsed latency: $LATENCY, loss: $LOSS"
echo "[$DATE] Current DNS IP: $CURRENT_IP"

if [[ -z "$LATENCY" || "$LOSS" -ge "$THRESHOLD_LOSS" || ( -n "$LATENCY" && "$(echo "$LATENCY > $THRESHOLD_LATENCY" | bc)" -eq 1 ) ]]; then
  if [[ "$CURRENT_IP" != "$BACKUP_IP" ]]; then
    echo "[$DATE] 🚨 Primary down! Switching DNS to backup IP ($BACKUP_IP)..."
    MESSAGE="🚨 ALERT: Primary TeamTalk ($PRIMARY_IP) down. Loss: ${LOSS}%, Latency: ${LATENCY}ms. Switching to backup: $BACKUP_IP"
    curl -v -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
      -d "chat_id=${CHAT_ID}" -d "text=${MESSAGE}"

    echo "[$DATE] 🔄 Sending DNS switch request to Cloudflare..."
    API_RESPONSE=$(curl -v -s -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${CF_RECORD_ID}" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" \
      -H "Content-Type: application/json" \
      --data "{\"type\":\"A\",\"name\":\"${DNS_NAME}\",\"content\":\"${BACKUP_IP}\",\"ttl\":60,\"proxied\":false}")
    echo "[$DATE] Cloudflare API response: $API_RESPONSE"
    echo "[$DATE] ✅ DNS switched to backup."
  else
    echo "[$DATE] 🔄 Primary down, but already on backup. No DNS change needed."
  fi
else
  if [[ "$CURRENT_IP" != "$PRIMARY_IP" ]]; then
    echo "[$DATE] ✅ Primary healthy! Switching DNS back to primary IP ($PRIMARY_IP)..."
    MESSAGE="✅ Primary TeamTalk ($PRIMARY_IP) back online. Loss: ${LOSS}%, Latency: ${LATENCY}ms. Switching DNS back to primary."
    curl -v -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
      -d "chat_id=${CHAT_ID}" -d "text=${MESSAGE}"

    echo "[$DATE] 🔄 Sending DNS switch back to Cloudflare..."
    API_RESPONSE=$(curl -v -s -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${CF_RECORD_ID}" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" \
      -H "Content-Type: application/json" \
      --data "{\"type\":\"A\",\"name\":\"${DNS_NAME}\",\"content\":\"${PRIMARY_IP}\",\"ttl\":60,\"proxied\":false}")
    echo "[$DATE] Cloudflare API response: $API_RESPONSE"
    echo "[$DATE] ✅ DNS switched back to primary."
  else
    echo "[$DATE] ✅ Primary healthy, already using primary IP. No DNS change needed."
  fi
fi
