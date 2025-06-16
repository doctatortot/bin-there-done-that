#!/bin/bash
# sync_to_vault.sh
# Rsync + ZFS sanity tool with built-in slash wisdom

set -euo pipefail

# === CONFIG ===
VAULT_HOST="thevault.sshjunkie.com"
BASE_TARGET="/nexus/miniodata/assets"

# === USAGE ===
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <source_dir> <bucket_name>"
  echo "Example: $0 /mnt/backup3/tempshit/genesisassets/ genesisassets-secure"
  exit 1
fi

SRC="$1"
BUCKET="$2"
DST="${BASE_TARGET}/${BUCKET}/"

# === WISDOM ===
echo "🧘 Trailing slashes, my friend. — John Northrup"
echo

if [[ "$SRC" != */ ]]; then
  echo "⚠️  Warning: Source path does not end in a slash."
  echo "    You may be copying the folder itself instead of its contents."
  echo "    You probably want: ${SRC}/"
  echo
fi

# === VERIFY SOURCE ===
if [[ ! -d "$SRC" ]]; then
  echo "❌ Source directory does not exist: $SRC"
  exit 1
fi

# === CREATE ZFS DATASET ON REMOTE IF MISSING ===
echo "🔍 Ensuring dataset exists on $VAULT_HOST..."
ssh root@$VAULT_HOST "zfs list nexus/miniodata/assets/$BUCKET" >/dev/null 2>&1 || {
  echo "📁 Creating dataset nexus/miniodata/assets/$BUCKET on $VAULT_HOST"
  ssh root@$VAULT_HOST "zfs create nexus/miniodata/assets/$BUCKET"
}

# === RSYNC ===
echo "🚀 Starting rsync from $SRC to $VAULT_HOST:$DST"
rsync -avhP "$SRC" root@$VAULT_HOST:"$DST"

# === SNAPSHOT ===
SNAPNAME="rsync_$(date +%Y%m%d_%H%M%S)"
echo "📸 Creating post-sync snapshot: $SNAPNAME"
ssh root@$VAULT_HOST "zfs snapshot nexus/miniodata/assets/$BUCKET@$SNAPNAME"

# === DONE ===
echo "✅ Sync and snapshot complete: $BUCKET@$SNAPNAME"
