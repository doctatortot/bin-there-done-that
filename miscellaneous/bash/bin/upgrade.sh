#!/bin/bash

# ---- CONFIGURATION ----
DOMAIN="your.mastodon.domain"  # Replace this with your real domain
ACCOUNT_USERNAME="administration"
SCRIPT_PATH="/root/finish_upgrade.sh"
LOGFILE="/root/mastodon_upgrade_$(date +%F_%H-%M-%S).log"
exec > >(tee -a "$LOGFILE") 2>&1
set -e

echo "===== Mastodon 20.04 → 22.04 Upgrade Starter ====="

read -p "❗ Have you backed up your system and database? (yes/no): " confirmed
if [[ "$confirmed" != "yes" ]]; then
  echo "❌ Aborting. Please take a backup."
  exit 1
fi

echo "🔧 Updating system..."
apt update && apt upgrade -y
apt install update-manager-core curl -y

echo "🛑 Stopping Mastodon..."
systemctl stop mastodon-web mastodon-sidekiq mastodon-streaming

echo "🔁 Preparing post-reboot upgrade finalization..."

# ---- Create finish_upgrade.sh ----
cat << EOF > $SCRIPT_PATH
#!/bin/bash
LOGFILE="/root/mastodon_post_upgrade_\$(date +%F_%H-%M-%S).log"
exec > >(tee -a "\$LOGFILE") 2>&1
set -e

echo "===== Post-Reboot Finalization Script ====="

echo "🔄 Restarting Mastodon services..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl start mastodon-web mastodon-sidekiq mastodon-streaming

echo "✅ Checking service status..."
systemctl status mastodon-web --no-pager
systemctl status mastodon-sidekiq --no-pager
systemctl status mastodon-streaming --no-pager

echo "🌐 Homepage check..."
if curl --silent --fail https://$DOMAIN >/dev/null; then
  echo "✅ Homepage is reachable."
else
  echo "❌ Homepage failed to load."
fi

echo "📣 Posting announcement toot..."
cd /home/mastodon/live
sudo -u mastodon -H bash -c '
RAILS_ENV=production bundle exec rails runner "
acct = Account.find_by(username: \\"$ACCOUNT_USERNAME\\")
if acct
  PostStatusService.new.call(acct, text: \\"✅ Server upgrade to Ubuntu 22.04 complete. We\\'re back online!\\")
end
"'

echo "🧹 Cleaning up..."
apt autoremove -y && apt autoclean -y

echo "🚫 Removing rc.local to prevent rerun..."
rm -f /etc/rc.local
rm -f $SCRIPT_PATH

echo "✅ Post-upgrade steps complete."
EOF

chmod +x $SCRIPT_PATH

# ---- Set rc.local to run after reboot ----
cat << EOF > /etc/rc.local
#!/bin/bash
bash $SCRIPT_PATH
exit 0
EOF

chmod +x /etc/rc.local

echo ""
echo "🚀 Starting do-release-upgrade..."
sleep 3
do-release-upgrade
