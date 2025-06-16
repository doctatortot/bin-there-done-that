#!/bin/bash

# Telegram Bot Token and Chat ID
TELEGRAM_BOT_TOKEN="8178867489:AAH0VjN7VnZSCIWasSz_y97iBLLjPJA751k"
TELEGRAM_CHAT_ID="1559582356"

# Function to send Telegram message
send_telegram_message() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id=$TELEGRAM_CHAT_ID \
    -d text="$message" > /dev/null
}

# Check if it's the first of the month and send a reminder
current_day=$(date +%d)
if [ "$current_day" -eq "01" ]; then
  send_telegram_message "Reminder: It's the 1st of the month! Please run a disaster recovery drill and test restore on all datasets."
fi
