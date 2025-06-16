#!/bin/bash
#
# Script Name: db2_zfs_backup.sh
# Description: Creates a raw base backup of PostgreSQL on zcluster.technodrome2 using pg_basebackup in directory mode.
#              Transfers the backup to The Vault’s ZFS dataset and snapshots it for long-term retention.
# Requirements: pg_basebackup, SSH access, rclone or rsync, ZFS dataset available at destination
# Usage: ./db2_zfs_backup.sh
# Author: Doc @ Genesis Ops
# Date: 2025-05-12
#

### CONFIGURATION ###
SOURCE_SERVER="zcluster.technodrome2.sshjunkie.com"
SOURCE_USER="doc"
PG_USER="postgres"
SOURCE_BASE_DIR="/tmp/db2_backup"  # On the remote node
BACKUP_LABEL="$(date +%Y%m%d%H%M)"
REMOTE_BACKUP_DIR="$SOURCE_BASE_DIR/$BACKUP_LABEL"

# Remote source rclone config (optional)
SOURCE_REMOTE="technodrome2"

# Local destination
DEST_DATASET="vaultpool/postgresql/db2"   # Adjust as needed
DEST_MOUNT="/nexus/postgresql/db2"        # Must be mountpoint for $DEST_DATASET
FULL_DEST="$DEST_MOUNT/$BACKUP_LABEL"

#####################

echo "🚀 Starting ZFS-aware base backup for db2 from $SOURCE_SERVER..."

# Ensure pg_basebackup will run cleanly
ssh $SOURCE_USER@$SOURCE_SERVER "sudo mkdir -p '$REMOTE_BACKUP_DIR' && \
    sudo pg_basebackup -h localhost -D '$REMOTE_BACKUP_DIR' -U $PG_USER -Fp -R -X fetch -P"

if [[ $? -ne 0 ]]; then
    echo "❌ pg_basebackup failed on $SOURCE_SERVER."
    exit 1
fi

echo "📦 Backup created on $SOURCE_SERVER at $REMOTE_BACKUP_DIR"

# Pull the backup using rsync (preserves structure + timestamps)
echo "🔄 Syncing backup to The Vault at $FULL_DEST..."
mkdir -p "$FULL_DEST"
rsync -avz --progress $SOURCE_USER@$SOURCE_SERVER:"$REMOTE_BACKUP_DIR/" "$FULL_DEST/"

if [[ $? -ne 0 ]]; then
    echo "❌ rsync transfer failed!"
    exit 1
fi

# Snapshot the full ZFS backup dataset
SNAPSHOT_NAME="${DEST_DATASET}@${BACKUP_LABEL}"
echo "📸 Creating ZFS snapshot: $SNAPSHOT_NAME"
zfs snapshot "$SNAPSHOT_NAME"

if [[ $? -eq 0 ]]; then
    echo "✅ Snapshot $SNAPSHOT_NAME created successfully."
else
    echo "❌ Snapshot creation failed."
    exit 1
fi

# Optional: Clean up the remote backup dir
echo "🧹 Cleaning up temporary backup on $SOURCE_SERVER..."
ssh $SOURCE_USER@$SOURCE_SERVER "sudo rm -rf '$REMOTE_BACKUP_DIR'"

echo "🎉 Backup and ZFS snapshot complete. Stored in $FULL_DEST"
