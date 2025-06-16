#!/usr/bin/env bash

# snapshot_and_send_to_vault.sh
# Create a ZFS snapshot of /deadbeef/genesis-tools and send it to the vault

set -euo pipefail

# ⚙️ Config
POOL="deadbeef"
DATASET="genesis-tools"
REMOTE_USER="root"
REMOTE_HOST="thevault.bounceme.net"
REMOTE_DATASET="backups/krang"

# 🗓️ Create snapshot name
DATE=$(date +%F)
SNAPSHOT_NAME="${DATE}"

echo "🔧 Creating snapshot ${POOL}/${DATASET}@${SNAPSHOT_NAME}..."
sudo zfs snapshot ${POOL}/${DATASET}@${SNAPSHOT_NAME}

echo "🚀 Sending snapshot to ${REMOTE_HOST}..."
sudo zfs send ${POOL}/${DATASET}@${SNAPSHOT_NAME} | \
  ssh ${REMOTE_USER}@${REMOTE_HOST} sudo zfs receive -F ${REMOTE_DATASET}

echo "✅ Snapshot ${SNAPSHOT_NAME} replicated to ${REMOTE_HOST}:${REMOTE_DATASET}"

echo "🎉 All done!"
