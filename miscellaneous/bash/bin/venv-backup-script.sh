#!/usr/bin/env bash
set -euo pipefail  # This ensures the script will stop execution if any command fails, and that unset variables will cause errors

### Configuration ###
# Setting the root directory for virtual environments
VENV_ROOT="/home/doc"
# Define the backup directory where backups will be stored locally
BACKUP_DIR="$VENV_ROOT/backups"
# Define the retention period for local backups in days. Older backups will be deleted.
RETENTION_DAYS=7   

# Remote settings for syncing backups to a remote server
# Define the SSH user for remote access
REMOTE_USER="root"
# Define the remote host (the server where backups will be stored)
REMOTE_HOST="thevault.bounceme.net"
# Define the path on the remote server where the backups will be stored
REMOTE_PATH="/mnt/backup3/pythonvenvs"

### Derived ###
# Generate a timestamp based on the current date and time to create unique backup file names
DATE=$(date +'%F_%H-%M-%S')
# Define the full path of the backup file to be created locally
BACKUP_FILE="$BACKUP_DIR/venvs_backup_$DATE.tar.gz"

# Ensure that the backup directory exists, and create it if it does not
mkdir -p "$BACKUP_DIR"

# 1) Find all virtual environments in the specified root directory
# We are searching for directories under $VENV_ROOT that contain a 'bin/activate' file
# This file is typically present in Python virtual environments
mapfile -t VENV_DIRS < <(
  find "$VENV_ROOT" -maxdepth 1 -type d \
    -exec test -f "{}/bin/activate" \; -print
)

# If no virtual environments are found, print an error and exit the script
if [ ${#VENV_DIRS[@]} -eq 0 ]; then
  echo "❌ No virtual environments found under $VENV_ROOT"
  exit 1
fi

# 2) Extract the basenames of the virtual environments to use in the backup process
VENV_NAMES=()
for path in "${VENV_DIRS[@]}"; do
  VENV_NAMES+=( "$(basename "$path")" )
done

# Inform the user about which virtual environments are being backed up
echo "🔄 Backing up virtual environments: ${VENV_NAMES[*]}"

# Create a tarball archive of the found virtual environments
# We use the '-C' option to change the directory to $VENV_ROOT before adding the directories
tar czf "$BACKUP_FILE" -C "$VENV_ROOT" "${VENV_NAMES[@]}"

# Notify the user that the local backup was saved successfully
echo "✅ Local backup saved to $BACKUP_FILE"

# 3) Push the backup to the remote server using rsync
# Notify the user that the backup is being uploaded
echo "📡 Sending backup to ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/"
# The rsync command synchronizes the backup file with the remote server
# -a: Archive mode (preserves symbolic links, permissions, etc.)
# -z: Compress file data during the transfer
# --progress: Show progress during the transfer
rsync -az --progress "$BACKUP_FILE" \
      "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/"

# Check the result of the rsync command. If it failed, print an error and exit.
if [ $? -ne 0 ]; then
  echo "❌ Remote sync failed!"
  exit 1
else
  echo "✅ Remote sync succeeded."
fi

# 4) Rotate old local backups
# Inform the user that old backups are being deleted
echo "🗑️ Removing local backups older than $RETENTION_DAYS days..."
# The 'find' command searches for backup files older than the retention period and deletes them
find "$BACKUP_DIR" -type f -name "venvs_backup_*.tar.gz" \
     -mtime +$RETENTION_DAYS -delete

# Notify the user that the backup and cleanup process is complete
echo "🎉 Backup and cleanup complete."
