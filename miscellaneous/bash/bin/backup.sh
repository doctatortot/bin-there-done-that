#!/bin/bash
#blargh
# Configuration
SRC_DIR="/home/mastodon/live"
DEST_DIR="/home/mastodon/backup"
PG_DB_NAME="mastodon_production"
PG_USER="mastodon"
PG_HOST=""  # Leave empty for local socket connection
PG_PORT="5432"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="${DEST_DIR}/mastodon_backup_${TIMESTAMP}"
LOG_FILE="${DEST_DIR}/backup_${TIMESTAMP}.log"

# Ensure the destination directory exists
mkdir -p "$BACKUP_DIR" || { echo "Failed to create backup directory"; exit 1; }

# Backup Mastodon files
echo "Starting rsync backup of Mastodon files..."
rsync -av --delete "$SRC_DIR" "$BACKUP_DIR/mastodon_files" >> "$LOG_FILE" 2>&1 || { echo "rsync failed"; exit 1; }

# Backup Nginx configuration files
echo "Starting backup of Nginx configuration files..."
rsync -av /etc/nginx "$BACKUP_DIR/nginx_configs" >> "$LOG_FILE" 2>&1 || { echo "rsync failed to backup Nginx configs"; exit 1; }

# Backup PostgreSQL database
echo "Starting PostgreSQL database backup..."
pg_dump -U "$PG_USER" -d "$PG_DB_NAME" > "$BACKUP_DIR/mastodon_db_${TIMESTAMP}.sql" >> "$LOG_FILE" 2>&1 || { echo "pg_dump failed"; exit 1; }

# Compress the backup
echo "Compressing backup..."
tar -czf "${BACKUP_DIR}.tar.gz" -C "$DEST_DIR" "mastodon_backup_${TIMESTAMP}" >> "$LOG_FILE" 2>&1 || { echo "Compression failed"; exit 1; }

# Remove the uncompressed backup directory
echo "Removing uncompressed backup directory..."
ls -l "$BACKUP_DIR" >> "$LOG_FILE" 2>&1  # Debugging output
rm -rf "$BACKUP_DIR" >> "$LOG_FILE" 2>&1 || { echo "Failed to remove uncompressed backup directory"; exit 1; }

# Transfer backup to remote server
REMOTE_USER="root"
REMOTE_HOST="209.209.9.128"
REMOTE_DIR="/mnt/e"

echo "Transferring backup to remote server..." >> "$LOG_FILE" 2>&1
rsync -av "${DEST_DIR}/mastodon_backup_${TIMESTAMP}.tar.gz" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}" >> "$LOG_FILE" 2>&1 || { echo "Remote rsync failed"; exit 1; }

# Remove local compressed backup file
echo "Removing local compressed backup file..." >> "$LOG_FILE" 2>&1
rm "${DEST_DIR}/mastodon_backup_${TIMESTAMP}.tar.gz" >> "$LOG_FILE" 2>&1 || { echo "Failed to remove local backup file"; exit 1; }

# Move log files to /home/mastodon/logs
LOG_DEST_DIR="/home/mastodon/logs"
mkdir -p "$LOG_DEST_DIR" >> "$LOG_FILE" 2>&1 || { echo "Failed to create log destination directory"; exit 1; }
mv "$LOG_FILE" "${LOG_DEST_DIR}/backup_${TIMESTAMP}.log" >> "$LOG_FILE" 2>&1 || { echo "Failed to move log file"; exit 1; }

# Clean up backup directory
echo "Cleaning up backup directory..." >> "$LOG_FILE" 2>&1
rm -rf "${DEST_DIR}"/* >> "$LOG_FILE" 2>&1 || { echo "Failed to clean up backup directory"; exit 1; }

echo "Backup completed: ${BACKUP_DIR}.tar.gz"
