#!/bin/bash

# GenesisSync: SPL Remote Sync Runner (Krang Orchestrated)
# Krang orchestrates sync by SSHing into Shredder, where the SPL shares live.

SHREDDER_HOST="shredder.sshjunkie.com"
SHREDDER_USER="doc"
REMOTE_SCRIPT="/tmp/genesis_sync_remote.sh"
LOGFILE="/home/doc/genesis_sync_spl.log"

# Telegram settings
TELEGRAM_BOT_TOKEN="AAFrXrxWVQyGxR6sBOKFPchQ3BsMdgqIZsY"
TELEGRAM_CHAT_ID="8127808884"

send_telegram() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d text="$message" \
    -d parse_mode="Markdown" > /dev/null
}

start_time=$(date +%s)
start_date=$(date)
echo "[GenesisSync] Starting remote SPL sync at $start_date" | tee -a "$LOGFILE"
send_telegram "🛠 *GenesisSync SPL (Remote) Started*
Time: $start_date" || true

# Generate the remote script that Shredder will execute
cat << 'EOF' > /tmp/genesis_sync_remote.sh
#!/bin/bash
MOUNT_BASE="/mnt/spl"
SPL_HOST="38.102.127.163"
SPL_USER="Administrator"
SPL_PASS="MutationXv3!"
HOT_BUCKET="genesis-hot:"
COLD_BUCKET="genesis-cold:"
LOGFILE="/tmp/genesis_sync_remote.log"

declare -A DIRS=(
  [splmedia]="splmedia"
  [splshows]="splshows"
  [splassets]="splassets"
)

echo "[GenesisSync:Shredder] Starting local operations at $(date)" > "$LOGFILE"

for key in "${!DIRS[@]}"; do
  share_name="${DIRS[$key]}"
  mount_point="$MOUNT_BASE/$share_name"
  local_path="$mount_point"

  mkdir -p "$mount_point"

  echo "[→] Mounting //$SPL_HOST/$share_name to $mount_point" >> "$LOGFILE"
  mount -t cifs "//$SPL_HOST/$share_name" "$mount_point" -o username="$SPL_USER",password="$SPL_PASS",vers=3.0 || echo "Mount failed for $share_name" >> "$LOGFILE"

  echo "[→] Rsync SPL ➝ Shredder: $key" >> "$LOGFILE"
  rsync -avz --delete "$mount_point/" "$local_path/" >> "$LOGFILE" 2>&1

  echo "[→] Rsync Shredder ➝ SPL (reverse): $key" >> "$LOGFILE"
  rsync -avzu "$local_path/" "$mount_point/" >> "$LOGFILE" 2>&1

  echo "[→] Unmounting $mount_point" >> "$LOGFILE"
  umount "$mount_point"

  echo "[→] Mirror ➝ ProtocolY: $key" >> "$LOGFILE"
  rclone sync "$local_path/" "$HOT_BUCKET/$share_name" --transfers=8 --log-file="$LOGFILE" --log-level INFO

  echo "[→] Mirror ➝ ProtocolZ: $key" >> "$LOGFILE"
  rclone sync "$local_path/" "$COLD_BUCKET/$share_name" --transfers=4 --log-file="$LOGFILE" --log-level INFO
done

echo "[✓] Shredder sync done at $(date)" >> "$LOGFILE"
EOF

# Push the script to Shredder
scp /tmp/genesis_sync_remote.sh "$SHREDDER_USER@$SHREDDER_HOST:$REMOTE_SCRIPT" > /dev/null 2>&1
ssh "$SHREDDER_USER@$SHREDDER_HOST" "chmod +x $REMOTE_SCRIPT && sudo $REMOTE_SCRIPT"

# Retrieve the log
scp "$SHREDDER_USER@$SHREDDER_HOST:/tmp/genesis_sync_remote.log" "$LOGFILE" > /dev/null 2>&1

end_time=$(date +%s)
duration=$((end_time - start_time))
end_date=$(date)
echo "[✓] GenesisSync (Remote) completed in ${duration}s at $end_date" | tee -a "$LOGFILE"
send_telegram "✅ *GenesisSync SPL Completed (Remote)*
Duration: ${duration}s
Finished: $end_date" || true

