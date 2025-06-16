#!/bin/bash

# Function to print dry-run actions and log them
dry_run_echo() {
    if [ "$DRY_RUN" = true ]; then
        echo "Dry run: $1"
    else
        eval $1
        STATUS=$?
        if [ $STATUS -eq 0 ]; then
            echo "Success: $1"
        else
            echo "Failure: $1"
            echo "$1 failed" >> "$LOG_FILE"
            exit 1  # Optionally exit on failure
        fi
    fi
}
# Configuration
REMOTE_USER="root"
REMOTE_HOST="38.102.127.167"  # New server IP
REMOTE_DIR="/home/mastodon"
PG_DB_NAME="mastodon_production"
PG_USER="mastodon"
PG_HOST="38.102.127.174"
PG_PORT="5432"
DRY_RUN=false  # Set to true for dry-run, false for actual migration
LOG_FILE="$(pwd)/migration_checklist_${TIMESTAMP}.log"  # Reuse the same log file

# Check if a dry run is requested
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "Dry run mode activated."
else
    echo "Running the migration for real."
fi

# Step 1: Install Glitch-Soc dependencies on the new server
dry_run_echo "Installing dependencies for Glitch-Soc on the new server..."
dry_run_echo "ssh root@${REMOTE_HOST} 'apt update && apt upgrade -y && apt install -y git curl wget vim unzip sudo build-essential libpq-dev libssl-dev libreadline-dev zlib1g-dev libyaml-dev libcurl4-openssl-dev libffi-dev libgdbm-dev nginx postgresql postgresql-contrib nodejs yarn ruby-full certbot python3-certbot-nginx'"

# Step 2: Clone Glitch-Soc and install
dry_run_echo "Cloning Glitch-Soc repository..."
dry_run_echo "ssh root@${REMOTE_HOST} 'git clone https://github.com/glitch-soc/glitch-soc.git /home/mastodon/live'"

dry_run_echo "Installing Mastodon dependencies on the new server..."
dry_run_echo "ssh root@${REMOTE_HOST} 'cd /home/mastodon/live && bundle install --deployment'"

dry_run_echo "Running Mastodon asset precompilation..."
dry_run_echo "ssh root@${REMOTE_HOST} 'cd /home/mastodon/live && RAILS_ENV=production bundle exec rake assets:precompile'"

dry_run_echo "Setting up Mastodon services..."
dry_run_echo "ssh root@${REMOTE_HOST} 'systemctl enable mastodon-web mastodon-sidekiq mastodon-streaming && systemctl start mastodon-web mastodon-sidekiq mastodon-streaming'"

# Step 3: Test if Mastodon and Nginx are running correctly
dry_run_echo "Checking if Nginx and Mastodon are running..."
dry_run_echo "ssh root@${REMOTE_HOST} 'curl --silent --head --fail http://localhost' || echo 'Nginx or Mastodon is not responding'"
dry_run_echo "ssh root@${REMOTE_HOST} 'ps aux | grep mastodon' || echo 'Mastodon process is not running'"
dry_run_echo "ssh root@${REMOTE_HOST} 'systemctl status nginx' || echo 'Nginx is not running'"

# Step 4: Test Database and S3 access
dry_run_echo "Verifying database and object storage access on the new server..."
dry_run_echo "ssh root@${REMOTE_HOST} 'psql -U mastodon -h $PG_HOST -d $PG_DB_NAME -c \"SELECT 1;\"' || echo 'Database connection failed'"
dry_run_echo "ssh root@${REMOTE_HOST} 'curl --silent --head --fail \"https://chatwithus-live.us-east-1.linodeobjects.com\"' || echo 'S3 storage is not reachable'"

# Step 5: Clean up backup directories
dry_run_echo "Cleaning up backup directory on the new server..."
dry_run_echo "ssh root@${REMOTE_HOST} 'rm -rf /home/mastodon/backup/*'"

# Step 6: Final Check
dry_run_echo "Final check: Ensure DNS is updated and pointing to new IP."
dry_run_echo "Check DNS configuration and ensure it points to $REMOTE_HOST."

echo "Migration (Part 2) completed."
