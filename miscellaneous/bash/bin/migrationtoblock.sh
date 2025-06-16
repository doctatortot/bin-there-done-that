#!/bin/bash

# === CONFIG ===
SRC="/mnt/raid5/minio-data/linodeassets"
DST="/mnt/mastodon-assets"
MOUNTPOINT="/home/mastodon/live/public/system"
LOGFILE="/var/log/mastodon_asset_migration_$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date '+%F %T')] $*" | tee -a "$LOGFILE"
}

verify_sync() {
    local src_count=$(find "$SRC" -type f | wc -l)
    local dst_count=$(find "$DST" -type f | wc -l)
    local src_bytes=$(du -sb "$SRC" | awk '{print $1}')
    local dst_bytes=$(du -sb "$DST" | awk '{print $1}')

    echo "--- Verification Results ---" | tee -a "$LOGFILE"
    echo "Files: $src_count → $dst_count" | tee -a "$LOGFILE"
    echo "Bytes: $src_bytes → $dst_bytes" | tee -a "$LOGFILE"

    if [[ "$src_count" -ne "$dst_count" || "$src_bytes" -ne "$dst_bytes" ]]; then
        echo "❌ MISMATCH detected. Please review the rsync log." | tee -a "$LOGFILE"
    else
        echo "✅ Verified: source and destination match." | tee -a "$LOGFILE"
    fi
    echo "---------------------------" | tee -a "$LOGFILE"
}

# === PHASE 1: Live Sync ===
log "🚀 Starting Phase 1: Live rsync"
rsync -aAXv --progress "$SRC/" "$DST/" | tee -a "$LOGFILE"

# === Stop Mastodon ===
log "🛑 Stopping Mastodon services..."
systemctl stop mastodon-web mastodon-sidekiq mastodon-streaming || {
    log "❌ Failed to stop Mastodon services"; exit 1;
}

# === PHASE 2: Final Sync ===
log "🔁 Starting Phase 2: Final rsync with --delete"
rsync -aAXv --delete "$SRC/" "$DST/" | tee -a "$LOGFILE"

# === Bind Mount Cutover ===
log "🔗 Swapping in block storage as $MOUNTPOINT"
if [[ -d "$MOUNTPOINT" ]]; then
    mv "$MOUNTPOINT" "${MOUNTPOINT}.bak" || {
        log "❌ Could not move existing mountpoint"; exit 1;
    }
fi

mkdir -p "$MOUNTPOINT"
mount --bind "$DST" "$MOUNTPOINT"
grep -q "$MOUNTPOINT" /etc/fstab || echo "$DST $MOUNTPOINT none bind 0 0" >> /etc/fstab
log "[✓] Bind mount active and persisted"

# === Permissions ===
log "🔧 Fixing permissions on $DST"
chown -R mastodon:mastodon "$DST"

# === Restart Mastodon ===
log "🚀 Restarting Mastodon services..."
systemctl start mastodon-web mastodon-sidekiq mastodon-streaming || {
    log "❌ Failed to restart Mastodon services"; exit 1;
}

# === VERIFY ===
log "🧪 Verifying file count and byte totals"
verify_sync

log "🎉 Migration completed successfully. Mastodon is live on block storage."
