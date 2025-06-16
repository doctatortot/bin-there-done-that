#!/bin/bash
set -euo pipefail

# === SSH Hosts ===
SHREDDER_HOST="doc@shredder.sshjunkie.com"
PORTAL_HOST="root@portal.genesishostingtechnologies.com"
DA_HOST="root@da.genesishostingtechnologies.com"
VAULT_HOST="root@thevault.bounceme.net"
DATE=$(date +%Y%m%d%H%M%S)

# === Telegram Setup ===
TG_TOKEN="7277705363:AAGSw5Pmcbf7IsSyZKMqU6PJ4VsVwdKLRH0"
TG_CHAT_ID="1559582356"

send_telegram() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
       -d "chat_id=$TG_CHAT_ID&text=$message"
}

send_telegram "🧠 Starting V2 Direct-to-Vault Backup Orchestration..."

# === Sanity Checks on TheVault and Shredder Mounts ===
send_telegram "🧪 Sanity check: vault & shredder mounts..."
#ssh -o BatchMode=yes $VAULT_HOST "zfs mount -a && ls /backups/azuracast /backups/krang /backups/directadmin" || send_telegram "❌ Vault sanity check FAILED!"
#ssh -o BatchMode=yes $SHREDDER_HOST "
#  zfs mount assets/splmedia &&
#  zfs mount assets/azuracast &&
#  zfs mount assets/splshows &&
#  ls /assets/splmedia /assets/azuracast /assets/splshows
#"

# === 1️⃣ Direct SPL data: Shredder → TheVault ===
send_telegram "🔄 Syncing SPL data directly from Shredder to TheVault..."
ssh -o BatchMode=yes $SHREDDER_HOST "rsync -avz /mnt/spl/splmedia/ $VAULT_HOST:/backups/splmedia/$DATE/"
ssh -o BatchMode=yes $SHREDDER_HOST "rsync -avz /mnt/spl/splassets/ $VAULT_HOST:/backups/splassets/$DATE/"
ssh -o BatchMode=yes $SHREDDER_HOST "rsync -avz /mnt/spl/splshows/ $VAULT_HOST:/backups/splshows/$DATE/"
send_telegram "✅ SPL data sync complete!"

# === 2️⃣ Direct AzuraCast media: Shredder → TheVault ===
send_telegram "🔄 Syncing AzuraCast media directly from Shredder to TheVault..."
ssh -o BatchMode=yes $SHREDDER_HOST "rsync -avz /mnt/shredder.sshjunkie.com/azuracast/ $VAULT_HOST:/backups/azuracast/$DATE/"
send_telegram "✅ AzuraCast media sync complete!"

# === 3️⃣ Direct AzuraCast configs: Portal → TheVault ===
send_telegram "🔄 Syncing AzuraCast configs from Portal to TheVault..."
ssh -o BatchMode=yes $PORTAL_HOST "rsync -avz /var/azuracast/.env /var/azuracast/docker-compose.yml /var/azuracast/stations $VAULT_HOST:/backups/azuracast/configs/$DATE/"
send_telegram "✅ AzuraCast configs sync complete!"

# === 4️⃣ Direct AzuraCast DB dump: Portal → TheVault ===
send_telegram "🔄 Dumping and pushing AzuraCast DB from Portal to TheVault..."
ssh -o BatchMode=yes $PORTAL_HOST "pg_dump -U postgres azuracast | ssh $VAULT_HOST 'cat > /backups/azuracast/configs/$DATE/azuracast.sql'"
send_telegram "✅ AzuraCast DB push complete!"

# === 5️⃣ Direct DirectAdmin backup: Portal → TheVault ===
send_telegram "🔄 Syncing DirectAdmin configs from Portal to TheVault..."
ssh -o BatchMode=yes $PORTAL_HOST "rsync -avz /usr/local/directadmin/data/admin/ $VAULT_HOST:/backups/directadmin/$DATE/"
send_telegram "✅ DirectAdmin sync complete!"

# === 6️⃣ Krang's Proxmox configs: Krang → TheVault ===
send_telegram "🔄 Syncing Krang configs to TheVault..."
rsync -avz /etc/pve $VAULT_HOST:/backups/krang/$DATE/pve/
rsync -avz /etc/network/interfaces $VAULT_HOST:/backups/krang/$DATE/network/
rsync -avz /etc/ssh $VAULT_HOST:/backups/krang/$DATE/ssh/
send_telegram "✅ Krang configs push complete!"

# === 🎉 All done! ===
send_telegram "🎉 V2 Direct-to-Vault Backup COMPLETED!"
exit 0
