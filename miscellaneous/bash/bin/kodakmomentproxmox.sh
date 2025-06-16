#!/usr/bin/env bash
set -euo pipefail

### CONFIG ###
PROXMOX_HOST="root@38.102.127.162"
VMIDS=(101 103 104 105 106 108)
DEST_HOST="root@thevault.bounceme.net"
DEST_PATH="/mnt/backup3/vzdump"
TIMESTAMP=$(date +%F_%H-%M)
RETENTION_DAYS=7

echo "📦 Starting selective VM backup via KodakMoment..."

# Ensure base destination directory exists
echo "📁 Ensuring remote backup directory exists..."
ssh "$DEST_HOST" "mkdir -p '$DEST_PATH'"

for VMID in "${VMIDS[@]}"; do
  if [[ "$VMID" == "101" ]]; then
    echo "🎶 VM 101 is a music VM — using rsync instead of vzdump..."
    ssh doc@portal.genesishostingtechnologies.com \
      "rsync -avh /var/lib/docker/volumes/azuracast_station_data/_data/ $DEST_HOST:/mnt/backup3/azuracast/"
    echo "✅ Music files from VM 101 synced to thevault."
  else
    REMOTE_FILE="$DEST_PATH/vzdump-qemu-${VMID}-$TIMESTAMP.vma.zst"
    echo "🧠 Streaming snapshot backup of VM $VMID to $REMOTE_FILE..."

    ssh "$PROXMOX_HOST" \
      "vzdump $VMID --mode snapshot --compress zstd --stdout --storage local-lvm" | \
      ssh "$DEST_HOST" \
      "cat > '$REMOTE_FILE'"

    echo "✅ VM $VMID streamed and saved to thevault."
  fi
done

echo "🧹 Pruning old vzdump backups on thevault..."
ssh "$DEST_HOST" "find '$DEST_PATH' -type f -mtime +$RETENTION_DAYS -name 'vzdump-qemu-*.zst' -delete"

echo "✅ KodakMoment complete — selective backups successful."
