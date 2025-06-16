#!/bin/bash

# === Prompt for Target ===
read -p "Enter SSH username: " USERNAME
read -p "Enter server hostname (e.g. krang.internal): " HOSTNAME

REMOTE="$USERNAME@$HOSTNAME"

# === Alert Config (local alerts) ===
TELEGRAM_BOT_TOKEN="8178867489:AAH0VjN7VnZSCIWasSz_y97iBLLjPJA751k"
TELEGRAM_CHAT_ID="1559582356"
MASTODON_INSTANCE="https://chatwithus.live"
MASTODON_TOKEN="rimxBLi-eaJAcwagkmoj6UoW7Lc473tQY0cOM041Euw"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# === Remote Disk Check + Cleanup Script ===
REMOTE_SCRIPT=$(cat << 'EOF'
#!/bin/bash
THRESHOLD_PERCENT=15
HOST=$(hostname)
ALERTED=false

df -h --output=target,pcent | tail -n +2 | while read -r mount usage; do
  percent=$(echo "$usage" | tr -d '%')
  if [ "$percent" -ge $((100 - THRESHOLD_PERCENT)) ]; then
    echo "[!] $HOST: Low space on $mount ($usage used). Running cleanup..."

    apt-get clean -y > /dev/null 2>&1
    journalctl --vacuum-time=3d > /dev/null 2>&1
    docker system prune -af --volumes > /dev/null 2>&1
    rm -rf /tmp/* /var/tmp/*

    echo "[✓] $HOST: Cleanup complete for $mount"
  else
    echo "[OK] $HOST: $mount has enough space ($usage used)"
  fi
done
EOF
)

# === Run Remote Script via SSH ===
echo "[*] Connecting to $REMOTE..."
OUTPUT=$(ssh "$REMOTE" "$REMOTE_SCRIPT")

# === Log and Notify ===
echo "[$TIMESTAMP] === Remote Disk Check on $HOSTNAME ===" >> /var/log/disk_mitigator.log
echo "$OUTPUT" >> /var/log/disk_mitigator.log

# Alert if low space was found
if echo "$OUTPUT" | grep -q "\[!\]"; then
  MSG="⚠️ Disk cleanup triggered on $HOSTNAME via Krang.\n\n$OUTPUT"

  # Send alerts
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d text="$MSG" > /dev/null

  curl -s -X POST "$MASTODON_INSTANCE/api/v1/statuses" \
    -H "Authorization: Bearer $MASTODON_TOKEN" \
    -d "status=$MSG" \
    -d "visibility=unlisted" > /dev/null
fi

echo "[✓] Done. Output logged and alerts (if any) sent."
