#!/bin/bash

echo "Step 0: Starting script..."

# Load token from ~/.mastodon-token or environment
TOKEN_FILE="$HOME/.mastodon-token"
if [ -f "$TOKEN_FILE" ]; then
  export MASTO_TOKEN=$(cat "$TOKEN_FILE")
fi

if [ -z "$MASTO_TOKEN" ]; then
  echo "❌ No Mastodon access token found. Set \$MASTO_TOKEN or create ~/.mastodon-token"
  exit 1
fi

echo "Step 1: Token loaded."

TMPFILE=$(mktemp)
MASTO_API="https://chatwithus.live/api/v1/statuses"

SERVICES=(
  "Genesis Radio|https://genesis-radio.net"
  "Mastodon|https://chatwithus.live"
  "MinIO|https://console.sshjunkie.com"
  "AzuraCast|portal.genesishostingtechnologies.com/login"
  "TeamTalk|tcp://tt.themediahub.org:10442"
  "DirectAdmin|https://da.genesishostingtechnologies.com"
)

echo "[Status Check @ $(date -u '+%H:%M %Z')]" > "$TMPFILE"

for service in "${SERVICES[@]}"; do
  IFS="|" read -r NAME URL <<< "$service"

  if [[ $URL == tcp://* ]]; then
    # Handle TCP port check
    HOSTPORT=${URL#tcp://}
    HOST=${HOSTPORT%%:*}
    PORT=${HOSTPORT##*:}
    echo "Checking TCP: $NAME on $HOST:$PORT"
    timeout 5 bash -c "</dev/tcp/$HOST/$PORT" &>/dev/null
  else
    # Handle HTTP(S) check
    echo "Checking HTTP: $NAME -> $URL"
    curl -s --head --fail --max-time 5 "$URL" >/dev/null
  fi

  if [ $? -eq 0 ]; then
    echo "✅ $NAME: Online" >> "$TMPFILE"
  else
    echo "❌ $NAME: Offline" >> "$TMPFILE"
  fi
done

echo "Step 2: Results collected."
cat "$TMPFILE"

# Convert newlines to URL-encoded format
POST_BODY=$(sed ':a;N;$!ba;s/\n/%0A/g' "$TMPFILE")

echo "Step 3: Posting to Mastodon..."

curl -s -X POST "$MASTO_API" \
  -H "Authorization: Bearer $MASTO_TOKEN" \
  -d "status=$POST_BODY"

echo "Step 4: Done."

rm -f "$TMPFILE"
