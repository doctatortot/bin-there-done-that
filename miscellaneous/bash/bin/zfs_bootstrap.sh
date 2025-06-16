#!/bin/bash

set -euo pipefail

# CONFIGURATION
ORIG_MINIO_PATH="/assets"
NEW_ZFS_PATH="/zfs/disk1"
MINIO_BUCKETS=(
  "assets_azuracast"
  "assets_archives"
  "assets_genesisassets"
  "assets_genesislibrary"
  "assets_mastodon"
  "assets_teamtalkdata"
)
MINIO_USER="minio-user"
MINIO_SERVICE="minio"

echo "=== Step 1: Preparing new ZFS path ==="
mkdir -p "$NEW_ZFS_PATH"

for BUCKET in "${MINIO_BUCKETS[@]}"; do
  CLEAN_NAME="${BUCKET/assets_/}"  # Remove 'assets_' prefix
  SRC="$ORIG_MINIO_PATH/$BUCKET/"
  DEST="$NEW_ZFS_PATH/$CLEAN_NAME/"

  echo "=== Step 2: Rsyncing $BUCKET → $CLEAN_NAME ==="
  rsync -a --info=progress2 "$SRC" "$DEST"

  echo "=== Step 3: Fixing ownership for: $CLEAN_NAME ==="
  chown -R "$MINIO_USER:$MINIO_USER" "$DEST"
done

echo "=== Step 4: Update MinIO service (manual step) ==="
echo "Set ExecStart in minio.service to:"
echo "  /usr/local/bin/minio server $NEW_ZFS_PATH --console-address \":9001\""

echo "=== Step 5: Reload and restart MinIO ==="
echo "Run:"
echo "  systemctl daemon-reload"
echo "  systemctl restart $MINIO_SERVICE"

echo "=== Step 6: Validate with mc ==="
echo "Run:"
echo "  mc alias set local http://localhost:9000 genesisadmin MutationXv3!"
echo "  mc ls local/"

echo ""
echo "✅ All buckets (including teamtalkdata) are now synced to the ZFS backend."
echo "To roll back, revert minio.service ExecStart and restart MinIO."
