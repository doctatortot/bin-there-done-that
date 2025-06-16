#!/bin/bash

set -euo pipefail

# CONFIG
ZFS_PATH="/assets/"
MINIO_USER="minio-user"
EXPECTED_BUCKETS=(
  "assets_azuracast"
  "assets_archives"
  "assets_genesisassets"
  "assets_genesislibrary"
  "assets_mastodon"
  "assets_teamtalkdata"
)

echo "=== Verifying ZFS MinIO Layout in $ZFS_PATH ==="

for BUCKET in "${EXPECTED_BUCKETS[@]}"; do
  BUCKET_PATH="$ZFS_PATH/$BUCKET"
  echo "- Checking: $BUCKET_PATH"
  
  if [ -d "$BUCKET_PATH" ]; then
    echo "  ✅ Exists"
    OWNER=$(stat -c '%U' "$BUCKET_PATH")
    if [ "$OWNER" == "$MINIO_USER" ]; then
      echo "  ✅ Ownership correct: $OWNER"
    else
      echo "  ❌ Ownership incorrect: $OWNER"
    fi
  else
    echo "  ❌ Missing bucket directory!"
  fi
done

echo ""
echo "If MinIO is already running, run the following to confirm bucket visibility:"
echo "  mc alias set local http://localhost:9000 genesisadmin MutationXv3!"
echo "  mc ls local/"
