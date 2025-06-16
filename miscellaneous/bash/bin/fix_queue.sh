#!/bin/bash

# ===== CONFIG =====
USERNAME="$1"
RAILS_ENV=production
cd /home/mastodon/live || exit 1

if [[ -z "$USERNAME" ]]; then
  echo "❌ Usage: $0 <username>"
  exit 1
fi

echo "🔍 Looking up account ID for @$USERNAME..."
ACCOUNT_ID=$(sudo -u mastodon -H bundle exec rails runner "
acct = Account.find_by(username: '$USERNAME')
puts acct&.id || 'not_found'
")

if [[ "$ACCOUNT_ID" == "not_found" ]]; then
  echo "❌ Account @$USERNAME not found."
  exit 1
fi

echo "🗑️ Deleting Redis cache for home timeline..."
sudo -u mastodon -H redis-cli DEL feed:home:$ACCOUNT_ID

echo "🧱 Rebuilding timeline from followed accounts..."
sudo -u mastodon -H bundle exec rails runner "
acct = Account.find_by(username: '$USERNAME')
if acct
  FeedInsertWorker.push_bulk(acct.following.pluck(:id)) do |follower_id|
    [follower_id, acct.id]
  end
  puts '✅ Timeline repopulation enqueued.'
end
"

echo "✅ Done. Home timeline for @$USERNAME reset and rebuilt."
