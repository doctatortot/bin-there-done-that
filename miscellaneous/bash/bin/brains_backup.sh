#!/bin/bash
set -euo pipefail

# === SSH Hosts ===
SHREDDER_HOST="doc@shredder.sshjunkie.com"
PORTAL_HOST="root@portal.genesishostingtechnologies.com"
DA_HOST="root@da.genesishostingtechnologies.com"
VAULT_HOST="root@thevault.bounceme.net"

# === Telegram Setup ===
TG_TOKEN="7277705363:AAGSw5Pmcbf7IsSyZKMqU6PJ4VsVwdKLRH0"
TG_CHAT_ID="1559582356"

send_telegram() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
       -d "chat_id=$TG_CHAT_ID&text=$message"
}

# === Local Staging Area on Krang ===
STAGING_DATASET="/deadbeef/staging"
DATE=$(date +%Y%m%d%H%M%S)
BACKUP_DIR="$STAGING_DATASET/brains-$DATE"
mkdir -p "$BACKUP_DIR"

send_telegram "🧠 Starting centralized backup from Krang to $BACKUP_DIR..."

# === Sanity Checks on TheVault ===
send_telegram "🧪 Sanity check: ensuring TheVault datasets are mounted..."
ssh -o BatchMode=yes $VAULT_HOST "zfs mount -a && ls /backups/azuracast /backups/krang /backups/directadmin" && \
send_telegram "✅ TheVault mountpoints verified!" || \
send_telegram "❌ TheVault mountpoint sanity check FAILED!"

# === Sanity Checks on Shredder ===
send_telegram "🧪 Sanity check: ensuring Shredder datasets are mounted..."
ssh -o BatchMode=yes $SHREDDER_HOST "zfs mount -a && ls /assets/splmedia /assets/azuracast /assets/pokbackups /assets/splshows" && \
send_telegram "✅ Shredder mountpoints verified!" || \
send_telegram "❌ Shredder mountpoint sanity check FAILED!"

# === Helper Function for Steps ===
run_backup_step() {
  local description="$1"
  shift
  send_telegram "🔄 $description"
  if "$@"; then
    send_telegram "✅ $description complete!"
  else
    send_telegram "❌ $description FAILED!"
  fi
}

# === 1️⃣ Sync SPL and Shredder Data ===
run_backup_step "Syncing SPL and Shredder data" \
  rsync -avz -e "ssh -o BatchMode=yes" $SHREDDER_HOST:/mnt/spl/ "$BACKUP_DIR/splmedia/" && \
  rsync -avz -e "ssh -o BatchMode=yes" $SHREDDER_HOST:/mnt/spl/ "$BACKUP_DIR/splassets/"

# === 2️⃣ Backup Krang's Configs ===
run_backup_step "Backing up Krang host configs" \
  rsync -avz /etc/pve "$BACKUP_DIR/krang-pve/" && \
  rsync -avz /etc/network/interfaces "$BACKUP_DIR/krang-net/" && \
  rsync -avz /etc/ssh "$BACKUP_DIR/krang-ssh/"

# === 3️⃣ Backup AzuraCast DB from Portal ===
run_backup_step "Backing up AzuraCast DB from Portal" \
  ssh -o BatchMode=yes $PORTAL_HOST "pg_dump -U postgres azuracast" > "$BACKUP_DIR/databases/azuracast.sql"

# === 4️⃣ Backup AzuraCast Configs ===
run_backup_step "Backing up AzuraCast configs from Portal" \
  rsync -avz -e "ssh -o BatchMode=yes" $PORTAL_HOST:/var/azuracast/.env "$BACKUP_DIR/azuracast/" && \
  rsync -avz -e "ssh -o BatchMode=yes" $PORTAL_HOST:/var/azuracast/docker-compose.yml "$BACKUP_DIR/azuracast/" && \
  rsync -avz -e "ssh -o BatchMode=yes" $PORTAL_HOST:/var/azuracast/stations "$BACKUP_DIR/azuracast/stations"

# === 5️⃣ Sync AzuraCast Media from Portal to Shredder, then to Krang ===
run_backup_step "Syncing AzuraCast media from Portal to Shredder" \
  ssh -o BatchMode=yes $PORTAL_HOST "rsync -avz /mnt/azuracast1/ doc@shredder.sshjunkie.com:/assets/azuracast/"

run_backup_step "Backing up AzuraCast media from Shredder to Krang" \
  rsync -avz -e "ssh -o BatchMode=yes" $SHREDDER_HOST:/assets/azuracast/ "$BACKUP_DIR/azuracast-media/"

# === 6️⃣ Backup DirectAdmin Configs ===
run_backup_step "Backing up DirectAdmin from Portal" \
  rsync -avz -e "ssh -o BatchMode=yes" $DA_HOST:/usr/local/directadmin/data/admin/ "$BACKUP_DIR/directadmin/"

# === 7️⃣ Push to TheVault ===
send_telegram "🔄 Pushing backups to TheVault datasets..."

# AzuraCast Configs & DB
rsync -avz -e "ssh -o BatchMode=yes" "$BACKUP_DIR/azuracast/" $VAULT_HOST:/backups/azuracast/configs/$DATE/
rsync -avz -e "ssh -o BatchMode=yes" "$BACKUP_DIR/databases/" $VAULT_HOST:/backups/azuracast/configs/$DATE/

# AzuraCast Media
rsync -avz -e "ssh -o BatchMode=yes" "$BACKUP_DIR/azuracast-media/" $VAULT_HOST:/backups/azuracast/$DATE/

# DirectAdmin
rsync -avz -e "ssh -o BatchMode=yes" "$BACKUP_DIR/directadmin/" $VAULT_HOST:/backups/directadmin/$DATE/

# Krang
rsync -avz -e "ssh -o BatchMode=yes" "$BACKUP_DIR/krang-*/" $VAULT_HOST:/backups/krang/$DATE/

# SPL
rsync -avz -e "ssh -o BatchMode=yes" "$BACKUP_DIR/splmedia/" $VAULT_HOST:/backups/splmedia/$DATE/
rsync -avz -e "ssh -o BatchMode=yes" "$BACKUP_DIR/splassets/" $VAULT_HOST:/backups/splassets/$DATE/

send_telegram "🎉 FULL SYSTEM BACKUP COMPLETED & MIRRORED TO VAULT!"
exit 0
