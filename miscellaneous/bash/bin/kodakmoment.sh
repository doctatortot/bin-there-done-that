#!/usr/bin/env bash
set -euo pipefail

### CONFIG ###
SOURCE_DIR="/home/doc/genesis-tools"
DEST_HOST="root@backup.sshjunkie.com"
DEST_PATH="/mnt/backup/images/genesis-tools"
REMOTE_LATEST_LINK="$DEST_PATH/latest"
RETENTION_DAYS=7

# Timestamp-based vars (only when running a snapshot)
TIMESTAMP=$(date +%F_%H-%M)
SNAPSHOT_NAME="$TIMESTAMP"
REMOTE_SNAP_DIR="$DEST_PATH/$SNAPSHOT_NAME"

# --dry-run support
DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
  echo "🧪 Running in dry-run mode..."
  DRY_RUN="--dry-run"
fi

# --list support
if [[ "${1:-}" == "--list" ]]; then
  echo "📂 Available snapshots on $DEST_HOST:"
  ssh "$DEST_HOST" "ls -1 $DEST_PATH | sort"
  exit 0
fi

# --restore <timestamp> support
if [[ "${1:-}" == "--restore" && -n "${2:-}" ]]; then
  RESTORE_TIMESTAMP="$2"
  RESTORE_REMOTE_PATH="$DEST_PATH/$RESTORE_TIMESTAMP"

  echo "🧾 Restoring snapshot $RESTORE_TIMESTAMP from $DEST_HOST..."
  ssh "$DEST_HOST" "[ -d '$RESTORE_REMOTE_PATH' ]" || {
    echo "❌ Snapshot $RESTORE_TIMESTAMP does not exist."
    exit 1
  }

  echo "⚠️  This will overwrite files in $SOURCE_DIR with those from snapshot."
  read -rp "Continue? (y/n): " confirm
  if [[ "$confirm" != "y" ]]; then
    echo "❌ Restore cancelled."
    exit 1
  fi

  rsync -a --delete -e ssh "$DEST_HOST:$RESTORE_REMOTE_PATH/" "$SOURCE_DIR/"
  echo "✅ Restore from $RESTORE_TIMESTAMP complete."
  exit 0
fi

# Regular snapshot mode starts here
# Verify source directory exists
if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "❌ ERROR: Source directory $SOURCE_DIR does not exist."
  exit 1
fi

# Make sure destination path exists on the remote
echo "📂 Ensuring remote path exists..."
ssh "$DEST_HOST" "mkdir -p '$DEST_PATH'"

# Determine whether to use --link-dest based on presence of 'latest'
REMOTE_LD_OPTION=""
if ssh "$DEST_HOST" "[ -e '$REMOTE_LATEST_LINK' ]"; then
  REMOTE_LD_OPTION="--link-dest=$REMOTE_LATEST_LINK"
else
  echo "ℹ️  No 'latest' snapshot found — creating full backup."
fi

# Create snapshot via rsync with optional deduplication
echo "📸 Creating snapshot: $REMOTE_SNAP_DIR"
rsync -a --delete \
  --exclude="miscellaneous/kodakmoment.sh" \
  $DRY_RUN \
  $REMOTE_LD_OPTION \
  -e ssh "$SOURCE_DIR/" "$DEST_HOST:$REMOTE_SNAP_DIR"

# Only perform post-processing if not a dry-run
if [[ -z "$DRY_RUN" ]]; then
  echo "🔗 Updating 'latest' symlink..."
  ssh "$DEST_HOST" "rm -f '$REMOTE_LATEST_LINK'; ln -s '$REMOTE_SNAP_DIR' '$REMOTE_LATEST_LINK'"

  echo "🧹 Pruning snapshots older than $RETENTION_DAYS days..."
  ssh "$DEST_HOST" "find '$DEST_PATH' -maxdepth 1 -type d -mtime +$RETENTION_DAYS -exec rm -rf {} +"
fi

echo "✅ KodakMoment complete."
