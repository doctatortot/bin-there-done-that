#!/bin/bash

set -euo pipefail

# Base path where your current datasets are mounted
BASE_PATH="/assets"

# Mapping of underscore-named folders to dash-named equivalents
declare -A BUCKETS=(
  ["assets_azuracast"]="assets-azuracast"
  ["assets_archives"]="assets-archives"
  ["assets_genesisassets"]="assets-genesisassets"
  ["assets_genesislibrary"]="assets-genesislibrary"
  ["assets_teamtalkdata"]="assets-teamtalkdata"
)

echo "=== Copying underscore-named folders to dash-named MinIO bucket folders ==="
for SRC in "${!BUCKETS[@]}"; do
  DEST="${BUCKETS[$SRC]}"
  echo "📦 Copying $SRC to $DEST ..."
  rsync -a --info=progress2 "$BASE_PATH/$SRC/" "$BASE_PATH/$DEST/"
  chown -R minio-user:minio-user "$BASE_PATH/$DEST"
done

echo ""
echo "✅ Done. You can now point MinIO at these dash-named paths:"
for DEST in "${BUCKETS[@]}"; do
  echo "  /assets/$DEST"
done

echo "🔄 Then restart MinIO:"
echo "  systemctl daemon-reload && systemctl restart minio"
