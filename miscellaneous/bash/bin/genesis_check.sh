#!/bin/bash
mkdir -p /var/log/genesis_uptime

declare -A services=(
  [radio]="https://genesis-radio.net"
  [mastodon]="https://chatwithus.live"
  [minio]="https://console.sshjunkie.com"
  [azura]="https://portal.genesishostingtechnologies.com"
  [teamtalk]="http://tt.themediahub.org"
  [directadmin]="https://da.genesishostingtechnologies.com"
)

timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S")

for service in "${!services[@]}"
do
  url=${services[$service]}
  curl --head --silent --max-time 10 "$url" >/dev/null
  if [ $? -eq 0 ]; then
    echo "$timestamp,up" >> "/var/log/genesis_uptime/$service.log"
  else
    echo "$timestamp,down" >> "/var/log/genesis_uptime/$service.log"
  fi
done
