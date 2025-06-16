#!/bin/bash

# === CONFIG ===
REMOTE_USER="doc"
SERVERS=(
  thevault.sshjunkie.com
  zcluster.technodrome1.sshjunkie.com
  zcluster.technodrome2.sshjunkie.com
  shredder.sshjunkie.com
  chatwithus.live
)

SUDO_LINE="doc ALL=(ALL) NOPASSWD:ALL"

# === Execution ===
for HOST in "${SERVERS[@]}"; do
  echo "🔧 Fixing sudoers on $HOST..."

  ssh "$REMOTE_USER@$HOST" "sudo bash -c '
    cp /etc/sudoers /etc/sudoers.bak_krang &&
    grep -q \"$SUDO_LINE\" /etc/sudoers ||
    echo \"$SUDO_LINE\" >> /etc/sudoers &&
    visudo -c >/dev/null
  '"

  if ssh "$REMOTE_USER@$HOST" "sudo -n true"; then
    echo "✅ $HOST: sudo access confirmed"
  else
    echo "❌ $HOST: sudo access STILL broken"
  fi

  echo "----------------------------------"
done
