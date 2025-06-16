#!/bin/bash

# CONFIG
ZFS_BASE="/mnt/zfs_minio"
BUCKETS=(
  "assets-azuracastassets"
  "assets-genesisassets"
  "assets-genesislibrary"
  "assets-genesisarchives"
  "assets-mastodon"
)
SAMPLE_COUNT=5
USER="minio-user"
GROUP="minio-user"

# COLORS
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo "🔍 Validating migrated MinIO buckets..."
echo

for bucket in "${BUCKETS[@]}"; do
  OLD_PATH="${ZFS_BASE}/${bucket}"
  NEW_BUCKET=$(echo "$bucket" | tr '_' '-')
  NEW_PATH="${ZFS_BASE}/${NEW_BUCKET}"

  echo -e "${YELLOW}=== Bucket: $bucket → $NEW_BUCKET ===${NC}"

  if [[ ! -d "$OLD_PATH" || ! -d "$NEW_PATH" ]]; then
    echo -e "${RED}❌ Missing directory: ${OLD_PATH} or ${NEW_PATH}${NC}"
    echo
    continue
  fi

  # 1. File count check
  old_count=$(find "$OLD_PATH" -type f | wc -l)
  new_count=$(find "$NEW_PATH" -type f | wc -l)
  echo "📦 File count: $old_count (old) vs $new_count (new)"

  [[ "$old_count" -eq "$new_count" ]] && \
    echo -e "${GREEN}✅ File count matches${NC}" || \
    echo -e "${RED}❌ File count mismatch${NC}"

  # 2. Sample checksum
  echo "🔐 Verifying checksums for $SAMPLE_COUNT random files..."
  mismatch=0
  samples=$(find "$OLD_PATH" -type f | shuf -n "$SAMPLE_COUNT" 2>/dev/null)

  for file in $samples; do
    rel_path="${file#$OLD_PATH/}"
    old_sum=$(sha256sum "$OLD_PATH/$rel_path" | awk '{print $1}')
    new_sum=$(sha256sum "$NEW_PATH/$rel_path" | awk '{print $1}')

    if [[ "$old_sum" != "$new_sum" ]]; then
      echo -e "${RED}❌ Mismatch: $rel_path${NC}"
      ((mismatch++))
    else
      echo -e "${GREEN}✔ Match: $rel_path${NC}"
    fi
  done

  [[ "$mismatch" -eq 0 ]] && \
    echo -e "${GREEN}✅ All sample checksums match${NC}" || \
    echo -e "${RED}❌ $mismatch checksum mismatch(es) found${NC}"

  # 3. Ownership check
  ownership_issues=$(find "$NEW_PATH" ! -user "$USER" -o ! -group "$GROUP" | wc -l)
  [[ "$ownership_issues" -eq 0 ]] && \
    echo -e "${GREEN}✅ Ownership is correct${NC}" || \
    echo -e "${RED}❌ $ownership_issues ownership issues in $NEW_PATH${NC}"

  echo
done

echo -e "${YELLOW}📊 Validation complete. Review any ❌ issues before going live with MinIO.${NC}"
