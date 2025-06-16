#!/bin/bash
# Posts a Linux tip via Mastodon API, with fallback and logging

INSTANCE="https://chatwithus.live"      # <-- Change this!
TOKEN_FILE="/home/doc/genesis-tools/miscellaneous/bash/bin/mastodon_token.secret"
TIP_API="https://linuxtldr.com/api/tips/random"
FALLBACK_FILE="/home/doc/linux_tips.txt"
LOG_FILE="/home/doc/linux_masto_post.log"

# Load access token
if [[ ! -f "$TOKEN_FILE" ]]; then
    echo "Missing access token at $TOKEN_FILE"
    exit 1
fi
ACCESS_TOKEN=$(<"$TOKEN_FILE")

# Function to log and exit
fail_and_log() {
    echo "$(date): ERROR - $1" >> "$LOG_FILE"
    echo "⛔ $1"
    exit 1
}

# Try fetching a tip from API
response=$(curl -s "$TIP_API")

if echo "$response" | jq . >/dev/null 2>&1; then
    title=$(echo "$response" | jq -r '.title')
    tip=$(echo "$response" | jq -r '.tip')
    url=$(echo "$response" | jq -r '.url')
    POST="📘 *Linux Tip of the Day*\n\n$title\n\n$tip\n\n🔗 More: $url\n\n#Linux #CommandLine #SysAdmin"
else
    # API failed, use fallback
    if [[ ! -f "$FALLBACK_FILE" ]]; then
        fail_and_log "Both API and fallback file failed. No tips to post."
    fi
    POST="📘 *Linux Tip of the Day*\n\n$(shuf -n 1 "$FALLBACK_FILE")\n\n#Linux #CommandLine #SysAdmin"
    echo "$(date): Used fallback tip." >> "$LOG_FILE"
fi

# Post to Mastodon
resp=$(curl -s -X POST "$INSTANCE/api/v1/statuses" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -d "status=$POST" \
    -d "visibility=public")

# Check response
if echo "$resp" | grep -q '"id":'; then
    echo "$(date): ✅ Posted successfully: $(echo "$POST" | head -n 1)" >> "$LOG_FILE"
else
    fail_and_log "Post failed. Response: $resp"
fi
