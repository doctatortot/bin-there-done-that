#!/bin/bash
# Mastodon Media Audit: Find orphaned .part.* dirs & estimate space wasted
# For mounted MinIO (e.g., /assets/minio-data/mastodon)

TARGET="/assets/minio-data/mastodon/"
LOG="/tmp/mastodon_zombie_audit.log"
REPORT="/tmp/mastodon_zombie_report.txt"

echo "[*] Auditing .part.* zombie files under: $TARGET" | tee "$LOG"

# Find all part.1 or similar that are actually directories
find "$TARGET" -type d -name "part.*" > "$REPORT"

TOTAL=$(cat "$REPORT" | wc -l)
SIZE=$(du -shc $(cat "$REPORT" 2>/dev/null) 2>/dev/null | tail -1 | awk '{print $1}')

echo "[✔️] Found $TOTAL suspicious .part.* directories" | tee -a "$LOG"
echo "[📦] Estimated wasted space: $SIZE" | tee -a "$LOG"

echo "Top offenders:" | tee -a "$LOG"
du -sh $(cat "$REPORT" | head -n 20) 2>/dev/null | sort -hr | tee -a "$LOG"

echo -e "\n🚨 To delete these, run:\n  sudo xargs rm -rf < $REPORT" | tee -a "$LOG"
