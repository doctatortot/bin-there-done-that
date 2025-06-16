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
