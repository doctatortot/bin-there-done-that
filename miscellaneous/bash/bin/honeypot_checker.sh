#!/bin/bash
# Honeypot Self-Test Script for FailZero
# Run this from Krang or any box with access to the FailZero honeypot.

TARGET="$1"
PORT=22
USERNAME="admin"
TESTFILE="/opt/genesis/krang_config.yaml"

if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 <failzero_ip_or_hostname>"
  exit 1
fi

echo "🕵️  Starting honeypot self-test against $TARGET"

echo -e "\n[1/5] Scanning TCP port 22..."
nmap -p $PORT "$TARGET" | grep "$PORT"

echo -e "\n[2/5] Attempting SSH login to Cowrie..."
# This will hang briefly, then fail — Cowrie captures it
timeout 5s ssh -o StrictHostKeyChecking=no -p $PORT "$USERNAME@$TARGET" "echo test"

echo -e "\n[3/5] Running fake commands to trigger logs..."
timeout 5s ssh -o StrictHostKeyChecking=no -p $PORT "$USERNAME@$TARGET" "ls /; cat $TESTFILE; exit"

echo -e "\n[4/5] Re-checking open port..."
nmap -p $PORT "$TARGET" | grep "$PORT"

echo -e "\n[5/5] Checking for log entries (if local)..."
if [[ -f /home/cowrie/cowrie/var/log/cowrie/cowrie.log ]]; then
  echo "→ Tail of Cowrie log:"
  tail -n 5 /home/cowrie/cowrie/var/log/cowrie/cowrie.log
else
  echo "✓ If running remotely, check FailZero: /home/cowrie/cowrie/var/log/cowrie/cowrie.log"
fi

echo -e "\n✅ Honeypot self-test complete.
  - Cowrie should have captured a login + command attempt
  - Check Telegram for alerts if enabled
  - Check logs on FailZero for full details"
