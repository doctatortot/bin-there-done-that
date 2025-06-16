#!/bin/bash
# setup_genesis_tools.sh
# Creates the Genesis tools directory structure, installs scripts from src/*,
# auto-organizes loose src/ files into subfolders,
# logs what was installed, and optionally sets timestamps.

set -e

# Auto-organize any flat files in src/ into proper subfolders
TOOL_DIR="/home/doc/genesis-tools/miscellaneous/bash"
IMPORT_SCRIPT="$TOOL_DIR/import_src_flat.sh"

# Always regenerate the import script with latest logic
cat > "$IMPORT_SCRIPT" <<'EOS'
#!/bin/bash
# import_src_flat.sh
# Moves flat scripts/docs in src/ into bin/, archive/, or docs/ subfolders

BASE="/home/doc/genesis-tools/miscellaneous/bash/src"

# Ensure subfolders exist
mkdir -p "$BASE/bin" "$BASE/archive" "$BASE/docs"

# Move known bin scripts from src root
for script in \
  backup.sh clean_media.sh clean_orphans.sh clean_previewcards.sh \
  copydunkadunk.sh dasystemisdownyo.sh db2_backup.sh deldirectories.sh \
  disk_mitigator.sh dotheneedfuleverywhere.sh do_the_needful.sh \
  dr_mirror_to_linode.sh dr_telegram_alert.sh fix_queue.sh fix_queue2.sh fix_queue3.sh \
  fixsudoerseverywhere.sh freezermove.sh freezer.sh genesis_check.sh \
  genesis_sync_progress.sh get_telegram_id.sh giteapushv3.sh \
  hardenit.sh kodakmoment.sh kodakmomentproxmox.sh krang_backup.sh \
  krang_modular_health.sh malips.sh mastodon_restart.sh mastodon_status-check.sh \
  migrationtoblock.sh p1.sh p2.sh perms.sh pull_health_everywhere \
  pull_health_everywhere_ntp.sh restore.sh retention.sh \
  rsync_zfs_sync_helper.sh run_prune_from_krang.sh startemup.sh \
  sync.sh sync-to-vault.sh sync-trigger.sh tothebank.sh upgrade.sh \
  validate_zfs.sh venv-backup-script.sh verify_minio.sh verifypxe.sh watchdog.sh \
  zfs_bootstrap.sh; do
  if [ -f "$BASE/$script" ]; then
    mv -v "$BASE/$script" "$BASE/bin/"
  fi
done

# Move known archive scripts
mv -v "$BASE/krang_health_report.sh" "$BASE/archive/" 2>/dev/null || true

# Move docs
mv -v "$BASE/alerting.md" "$BASE/docs/" 2>/dev/null || true
mv -v "$BASE/README.md" "$BASE/" 2>/dev/null || true

exit 0
EOS
chmod +x "$IMPORT_SCRIPT"
bash "$IMPORT_SCRIPT"

# Define core tool paths
TOOL_DIR="/home/doc/genesis-tools/miscellaneous/bash"
SRC_DIR="$TOOL_DIR/src"
BIN_DIR="$TOOL_DIR/bin"
DOC_DIR="$TOOL_DIR/docs"
CONFIG_DIR="$TOOL_DIR/config"
LIB_DIR="$TOOL_DIR/lib"
ARCHIVE_DIR="$TOOL_DIR/archive"
LOG_FILE="$TOOL_DIR/setup_install.log"

mkdir -p "$BIN_DIR" "$DOC_DIR" "$CONFIG_DIR" "$LIB_DIR" "$ARCHIVE_DIR"
echo "[INFO] Setup run at $(date)" > "$LOG_FILE"

cp "$SRC_DIR/README.md" "$TOOL_DIR/README.md"
echo "[INSTALL] README.md copied to $TOOL_DIR" >> "$LOG_FILE"

# Copy scripts and log actions

echo "[*] Installing bin scripts..."
find "$SRC_DIR/bin" -type f -name "*.sh" | while read -r script; do
  echo "  → Installing $(basename "$script") to bin/"
  install -m 755 "$script" "$BIN_DIR/"
  echo "[INSTALL] $(basename "$script") installed to bin/" >> "$LOG_FILE"
done

echo "[*] Installing archive scripts..."
find "$SRC_DIR/archive" -type f -name "*.sh" | while read -r script; do
  echo "  → Installing $(basename "$script") to archive/"
  install -m 755 "$script" "$ARCHIVE_DIR/"
  echo "[INSTALL] $(basename "$script") installed to archive/" >> "$LOG_FILE"
done

echo "[*] Installing documentation..."
find "$SRC_DIR/docs" -type f -name "*.md" | while read -r doc; do
  echo "  → Copying $(basename "$doc") to docs/"
  cp "$doc" "$DOC_DIR/"
  echo "[INSTALL] $(basename "$doc") copied to docs/" >> "$LOG_FILE"
done

# Auto-generate Markdown documentation for each bin script with frontmatter
find "$SRC_DIR/bin" -type f -name "*.sh" | while read -r script; do
  base="$(basename "$script")"
  docfile="$DOC_DIR/${base%.sh}.md"
    echo "---" > "$docfile"
  echo "title: $base" >> "$docfile"
  tags=$(echo "$base" | grep -Eo 'backup|sync|fix|dr|monitor|mastodon|zfs|postgres|minio|disk|alert|verify|restore' | sort -u | tr '
' ' ' | sed 's/ $//')
  if [ -z "$tags" ]; then tags="uncategorized"; fi
  echo "categories: [${tags// /, }]" >> "$docfile"
  echo "source: bin/$base" >> "$docfile"
  echo "generated: $(date -Iseconds)" >> "$docfile"
  echo "---" >> "$docfile"
  echo >> "$docfile"
  echo "# $base" >> "$docfile"
  echo >> "$docfile"
  head -n 20 "$script" | grep '^#' | sed 's/^# //' >> "$docfile"
  echo >> "$docfile"
  echo "_Auto-generated from source script on $(date)_" >> "$docfile"
  echo "[DOCGEN] $base → $docfile" >> "$LOG_FILE"
done

# Create tool to summarize installed files
cat > "$TOOL_DIR/list_installed_tools.sh" <<'EOF'
#!/bin/bash
# list_installed_tools.sh
# Summarizes the most recent Genesis tools installation log

LOG_FILE="$(dirname "$0")/setup_install.log"

if [[ ! -f "$LOG_FILE" ]]; then
  echo "No installation log found at \$LOG_FILE"
  exit 1
fi

echo "📋 Installed Genesis Tools (from \$LOG_FILE):"
echo "--------------------------------------------------"
grep "\[INSTALL\]" "$LOG_FILE" | sed 's/\[INSTALL\] //' | sort
EOF
chmod +x "$TOOL_DIR/list_installed_tools.sh"

echo "Genesis Tools scaffold complete in: $TOOL_DIR"
echo "All scripts and docs copied from src/. Edit configs in $CONFIG_DIR before use."
echo "Installation log saved to $LOG_FILE"
echo "Run ./list_installed_tools.sh to view installed files."
