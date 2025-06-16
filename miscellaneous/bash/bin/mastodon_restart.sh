#!/bin/bash

# === CONFIG ===
SERVER="root@chatwithus.live"
MASTODON_INSTANCE="https://chatwithus.live"
ACCESS_TOKEN="07w3Emdw-cv_TncysrNU8Ed_sHJhwtnvKmnLqKlHmKA"

TOOT_VISIBILITY="public"

WARNING_TOOT_2M="🚨 Heads up! We’ll be restarting ChatWithUs.Live in about 2 minutes to perform routine maintenance and keep things running smoothly. Please wrap up anything important and hang tight — we’ll be right back."
WARNING_TOOT_1M="⚠️ Just one more minute until we restart the server. If you’re in the middle of something, now’s the time to save and log out. Thanks for your patience while we keep the gears turning!"

FINAL_TOOT="✅ ChatWithUs.Live services restarted from Krang via OPS script."

TELEGRAM_BOT_TOKEN="8178867489:AAH0VjN7VnZSCIWasSz_y97iBLLjPJA751k"
TELEGRAM_CHAT_ID="1559582356"
TELEGRAM_TEXT="✅ Mastodon has been restarted by Krang. All services are back online."

LOG_FILE="/home/doc/genesis-tools/masto_restart.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

{
echo "[$TIMESTAMP] === Mastodon Restart Initiated ==="

# === Post 2-Minute Warning Toot ===
echo "[*] Posting 2-minute warning to Mastodon..."
curl -s -X POST "$MASTODON_INSTANCE/api/v1/statuses" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "status=$WARNING_TOOT_2M" \
  -d "visibility=$TOOT_VISIBILITY" > /dev/null && echo "[✓] 2-minute warning posted."

# === Wait 1 minute ===
sleep 60

# === Post 1-Minute Warning Toot ===
echo "[*] Posting 1-minute warning to Mastodon..."
curl -s -X POST "$MASTODON_INSTANCE/api/v1/statuses" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "status=$WARNING_TOOT_1M" \
  -d "visibility=$TOOT_VISIBILITY" > /dev/null && echo "[✓] 1-minute warning posted."

# === Wait 1 more minute ===
sleep 60

# === Restart Mastodon Services ===
echo "[*] Connecting to $SERVER to restart Mastodon services..."

ssh "$SERVER" bash << 'EOF'
echo "Restarting mastodon-web..."
systemctl restart mastodon-web

echo "Restarting mastodon-sidekiq..."
systemctl restart mastodon-sidekiq

echo "Restarting mastodon-streaming..."
systemctl restart mastodon-streaming

echo "All services restarted."
EOF

# === Wait Until Mastodon API is Responsive ===
echo "[*] Waiting for Mastodon to come back online..."
until curl -sf "$MASTODON_INSTANCE/api/v1/instance" > /dev/null; do
    echo "   ... still starting up, retrying in 5s"
    sleep 5
done

echo "[+] Mastodon is back online."

# === Post Final Toot ===
echo "[*] Posting final status to Mastodon..."
curl -s -X POST "$MASTODON_INSTANCE/api/v1/statuses" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "status=$FINAL_TOOT" \
  -d "visibility=$TOOT_VISIBILITY" > /dev/null && echo "[✓] Final status posted."

# === Telegram Notification ===
echo "[*] Sending Telegram alert..."
curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d chat_id="$TELEGRAM_CHAT_ID" \
  -d text="$TELEGRAM_TEXT" > /dev/null && echo "[✓] Telegram alert sent."

echo "[✓] All tasks complete. Logged out of $SERVER."
echo "[$TIMESTAMP] === Mastodon Restart Complete ==="
echo ""

} >> "$LOG_FILE" 2>&1
