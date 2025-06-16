#!/bin/bash

# === CONFIG ===
REMOTE="root@thevault.sshjunkie.com"
SCRIPT_PATH="/root/prune_snapshots.sh"
LOG_FILE="/home/doc/genesis-tools/prune_trigger.log"
DRY_RUN=false

[[ "$1" == "--dry-run" ]] && DRY_RUN=true

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
echo "[$TIMESTAMP] Initiating snapshot prune on The Vault" >> "$LOG_FILE"

if $DRY_RUN; then
  ssh "$REMOTE" "bash $SCRIPT_PATH --dry-run"
else
  ssh "$REMOTE" "bash $SCRIPT_PATH"
fi
