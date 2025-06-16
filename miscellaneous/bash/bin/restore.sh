#!/bin/bash

# Configuration
REMOTE_SERVER="root@offsite.doctatortot.com"
REMOTE_BACKUP_DIR="/mnt/backup1/mastodon"
LOCAL_RESTORE_DIR="/home/mastodon/restore"
MASTODON_DIR="/home/mastodon/live"
PG_DB_NAME="mastodon_production"
PG_USER="mastodon"
PG_HOST=""  # Leave empty for local socket connection
PG_PORT="5432"

# Create the local restore directory if it doesn't exist
mkdir -p "$LOCAL_RESTORE_DIR" || { echo "Failed to create restore directory"; exit 1; }

# Find the latest backup file on the remote server
echo "Finding the latest backup file on the remote server..."
LATEST_BACKUP=$(ssh $REMOTE_SERVER "ls -t $REMOTE_BACKUP_DIR/mastodon_backup_*.tar.gz | head -n 1")

if [ -z "$LATEST_BACKUP" ]; then
  echo "No backup files found on the remote server."
  exit 1
fi

echo "Latest backup file found: $LATEST_BACKUP"

# Transfer the latest backup file to the local server
echo "Transferring the latest backup file to the local server..."
scp "$REMOTE_SERVER:$LATEST_BACKUP" "$LOCAL_RESTORE_DIR" || { echo "Failed to transfer backup file"; exit 1; }

# Extract the backup file
BACKUP_FILE=$(basename "$LATEST_BACKUP")
echo "Extracting the backup file..."
tar -xzf "$LOCAL_RESTORE_DIR/$BACKUP_FILE" -C "$LOCAL_RESTORE_DIR" || { echo "Failed to extract backup file"; exit 1; }

# Stop Mastodon services
echo "Stopping Mastodon services..."
sudo systemctl stop mastodon-web mastodon-sidekiq mastodon-streaming || { echo "Failed to stop Mastodon services"; exit 1; }

# Restore Mastodon files
echo "Restoring Mastodon files..."
rsync -av --delete "$LOCAL_RESTORE_DIR/mastodon_backup_*/mastodon_files/" "$MASTODON_DIR" || { echo "rsync failed"; exit 1; }

# Restore PostgreSQL database
echo "Restoring PostgreSQL database..."
PG_DUMP_FILE=$(find "$LOCAL_RESTORE_DIR" -name "mastodon_db_*.sql")
if [ -z "$PG_DUMP_FILE" ]; then
  echo "Database dump file not found."
  exit 1
fi

psql -U "$PG_USER" -d "$PG_DB_NAME" -f "$PG_DUMP_FILE" || { echo "psql restore failed"; exit 1; }

# Run database migrations
echo "Running database migrations..."
cd "$MASTODON_DIR"
RAILS_ENV=production bundle exec rails db:migrate || { echo "Database migrations failed"; exit 1; }

# Start Mastodon services
echo "Starting Mastodon services..."
sudo systemctl start mastodon-web mastodon-sidekiq mastodon-streaming || { echo "Failed to start Mastodon services"; exit 1; }

# Clean up
echo "Cleaning up..."
rm -rf "$LOCAL_RESTORE_DIR/mastodon_backup_*" || { echo "Failed to clean up restore files"; exit 1; }
rm "$LOCAL_RESTORE_DIR/$BACKUP_FILE" || { echo "Failed to remove backup file"; exit 1; }

echo "Restore completed successfully."
