#!/bin/bash

# === CONFIG ===
REPLICA_HOST="replica.db3.sshjunkie.com"
REPLICA_PORT=5432
REPLICA_USER="postgres"

BACKUP_SERVER="backup.sshjunkie.com"
BACKUP_DIR="/mnt/backup/pg_base"
WAL_DIR="/mnt/backup/wal"

REMOTE_USER="doc"
REMOTE_BASE="/var/lib/postgresql/16/base_restore"
REMOTE_WAL="/var/lib/postgresql/16/wal_archive"
REMOTE_PGDATA="/var/lib/postgresql/16/main"
REMOTE_HOST="replica.db3.sshjunkie.com"

TIMESTAMP=$(date +%F_%H%M%S)
TARGET_BASE="$BACKUP_DIR/$TIMESTAMP"
LOG_FILE="$HOME/pitr_logs/full_backup_and_pitr.log"

mkdir -p "$(dirname "$LOG_FILE")"
echo "[$(date '+%F %T')] === STARTING FULL BACKUP + PITR VALIDATION ===" | tee -a "$LOG_FILE"

# === STEP 1: Run pg_basebackup remotely on the backup server ===
echo "[*] Running pg_basebackup on $BACKUP_SERVER..." | tee -a "$LOG_FILE"
ssh "$BACKUP_SERVER" "mkdir -p '$TARGET_BASE' && pg_basebackup -h $REPLICA_HOST -p $REPLICA_PORT -U $REPLICA_USER -D '$TARGET_BASE' -Fp -Xs -P -R" >> "$LOG_FILE" 2>&1

if [[ $? -ne 0 ]]; then
  echo "❌ pg_basebackup failed!" | tee -a "$LOG_FILE"
  exit 1
fi

# === STEP 2: Rsync base backup to replica ===
echo "[*] Rsyncing base backup to $REMOTE_HOST..." | tee -a "$LOG_FILE"
rsync -avz --delete "$BACKUP_SERVER:$TARGET_BASE/" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_BASE/" >> "$LOG_FILE" 2>&1

# === STEP 3: Rsync WALs to replica ===
echo "[*] Rsyncing WALs to $REMOTE_HOST..." | tee -a "$LOG_FILE"
rsync -avz --delete "$BACKUP_SERVER:$WAL_DIR/" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_WAL/" >> "$LOG_FILE" 2>&1

# === STEP 4: SSH to replica and restore ===
echo "[*] Performing PITR on $REMOTE_HOST..." | tee -a "$LOG_FILE"
ssh "$REMOTE_USER@$REMOTE_HOST" bash << EOF
set -e

echo "[*] Stopping PostgreSQL..."
sudo -n systemctl stop postgresql@16-main

echo "[*] Cleaning PGDATA..."
sudo -n rm -rf $REMOTE_PGDATA/*
sudo -n mkdir -p $REMOTE_PGDATA
sudo -n chown postgres:postgres $REMOTE_PGDATA

echo "[*] Copying base backup..."
sudo -n cp -a $REMOTE_BASE/* $REMOTE_PGDATA/
sudo -n chown -R postgres:postgres $REMOTE_PGDATA

echo "[*] Removing stale recovery files..."
sudo -n rm -f $REMOTE_PGDATA/postmaster.pid $REMOTE_PGDATA/standby.signal $REMOTE_PGDATA/recovery.signal

echo "[*] Creating recovery config..."
sudo -n bash -c "cat > $REMOTE_PGDATA/postgresql.auto.conf << EOC
restore_command = 'cp $REMOTE_WAL/%f %p'
EOC"
sudo -n touch $REMOTE_PGDATA/recovery.signal

echo "[*] Starting PostgreSQL..."
sudo -n systemctl start postgresql@16-main
sleep 5

RECOVERY_STATE=\$(sudo -n -u postgres psql -U postgres -tAc "SELECT pg_is_in_recovery();")

if [[ "\$RECOVERY_STATE" == "f" ]]; then
  echo "[✓] Recovery complete."
else
  echo "[!] Still in recovery, promoting..."
  sudo -n systemctl restart postgresql@16-main
  sleep 5
fi

echo "[*] WAL replay point:"
sudo -n -u postgres psql -U postgres -tAc "SELECT pg_last_wal_replay_lsn(), now();"
EOF

echo "[✓] Full backup and PITR validation completed successfully." | tee -a "$LOG_FILE"
