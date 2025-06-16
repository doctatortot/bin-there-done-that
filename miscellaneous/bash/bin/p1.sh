#!/bin/bash

# Configuration
SRC_DIR="/home/mastodon/live"
DEST_DIR="/home/mastodon/backup"
PG_DB_NAME="mastodon_production"
PG_USER="mastodon"
PG_HOST="38.102.127.174"  # Use database IP
PG_PORT="5432"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="${DEST_DIR}/mastodon_backup"  # Removed the timestamp here for simplicity
LOG_FILE="$(pwd)/migration_checklist_${TIMESTAMP}.log"  # Create log file in the same directory
REMOTE_USER="root"
REMOTE_HOST="38.102.127.167"  # New server IP
REMOTE_DIR="/home/mastodon"

# Initialize the log file
echo "Migration checklist for real run on $(date)" > $LOG_FILE
echo "========================================" >> $LOG_FILE

# Step 1: Ensure necessary directories exist on the new server
echo "Checking if 'mastodon' user exists..." >> $LOG_FILE
id -u mastodon &>/dev/null || useradd -m mastodon

echo "Ensuring backup and log directories exist..." >> $LOG_FILE
mkdir -p /home/mastodon/mastodon_backup
mkdir -p /home/mastodon/logs

echo "Ensuring mastodon directory exists on remote server..." >> $LOG_FILE
mkdir -p "$DEST_DIR/mastodon_backup"

# Step 2: Check if the database is reachable
echo "Checking if the database is reachable..." >> $LOG_FILE
psql -U $PG_USER -h $PG_HOST -d $PG_DB_NAME -c 'SELECT 1;' || { echo "Database connection failed" >> $LOG_FILE; exit 1; }

# Step 3: Check if S3 storage is reachable
echo "Checking if S3 storage is reachable..." >> $LOG_FILE
curl --silent --head --fail 'https://chatwithus-live.us-east-1.linodeobjects.com' || echo 'S3 storage is not reachable' >> $LOG_FILE

# Step 4: Transfer files and directories
echo "Starting backup transfer..." >> $LOG_FILE

# Ensure the destination directory exists
mkdir -p $BACKUP_DIR

# Transfer Mastodon files from old server
rsync -avz --delete $SRC_DIR $BACKUP_DIR/mastodon_files  # The '-z' flag compresses the data during transfer

# Transfer Nginx config
rsync -avz /etc/nginx $BACKUP_DIR/nginx_configs  # Added compression for Nginx config transfer

# Backup PostgreSQL database
echo "Backing up PostgreSQL database..." >> $LOG_FILE
pg_dump -U $PG_USER -d $PG_DB_NAME > "$DEST_DIR/mastodon_db.sql"

# Ensure the backup directory is created (to be safe)
mkdir -p "$DEST_DIR/mastodon_backup"

# Compress the backup directory with tar (to reduce size)
echo "Creating backup archive..." >> $LOG_FILE
tar -czf "$DEST_DIR/mastodon_backup.tar.gz" -C "$DEST_DIR" mastodon_backup  # Compress the backup directory

# Step 5: Transfer backup to new server
echo "Transferring backup to new server..." >> $LOG_FILE
rsync -avz ${DEST_DIR}/mastodon_backup.tar.gz ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}  # Using compression during transfer

# Step 6: Remove local compressed backup file
rm ${DEST_DIR}/mastodon_backup.tar.gz

# Step 7: Move log files to /home/mastodon/logs
mv $LOG_FILE /home/mastodon/logs/backup_${TIMESTAMP}.log

# End of Part 1: Setup, checks, and transfer.
echo "Step 1-7 completed. Proceed with Part 2 to install Glitch-Soc." >> $LOG_FILE
