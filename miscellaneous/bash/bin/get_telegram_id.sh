#!/bin/bash

read -p "Enter your Telegram Bot Token: " TOKEN

echo "Fetching recent updates..."
curl -s "https://api.telegram.org/bot$TOKEN/getUpdates" | jq '.result[].message.chat | {id, type, title, username, first_name}'
