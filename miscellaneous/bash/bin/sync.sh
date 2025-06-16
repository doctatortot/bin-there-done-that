#!/bin/bash

# Setup alias (even if it already exists)
mc alias set minio http://localhost:9000 genesisadmin MutationXv3! || true

echo "[*] Syncing genesisassets → Q:"
mc mirror \
  --overwrite \
  --remove \
  --exclude "/System Volume Information/**" \
  --exclude "/$RECYCLE.BIN/**" \
  --exclude "**/Thumbs.db" \
  minio/genesisassets /mnt/spl/qdrive || echo "[!] Q: sync completed with warnings"

echo "[*] Syncing genesislibrary → R:"
mc mirror \
  --overwrite \
  --remove \
  --exclude "/System Volume Information/**" \
  --exclude "/$RECYCLE.BIN/**" \
  --exclude "**/Thumbs.db" \
  minio/genesislibrary /mnt/spl/rdrive || echo "[!] R: sync completed with warnings"

echo "[✓] All syncs finished"
