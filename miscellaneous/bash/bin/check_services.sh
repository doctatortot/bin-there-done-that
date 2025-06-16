#!/bin/bash
# check_services.sh – outputs JSON for frontend status page

check_ping() {
  ping -c1 -W1 "$1" >/dev/null 2>&1 && echo "online" || echo "offline"
}

check_tcp() {
  nc -z -w 2 "$1" "$2" >/dev/null 2>&1 && echo "online" || echo "offline"
}

TEAMTALK_STATUS=$(check_tcp tt.themediahub.org 10442)
DA_STATUS=$(check_tcp da.genesishostingtechnologies.com 2222)
SHREDDER_STATUS=$(check_ping shredder.sshjunkie.com)

cat <<EOF
{
  "teamtalk": "$TEAMTALK_STATUS",
  "directadmin": "$DA_STATUS",
  "shredder": "$SHREDDER_STATUS"
}
EOF
