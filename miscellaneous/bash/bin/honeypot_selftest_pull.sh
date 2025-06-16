#!/bin/bash
# Honeypot Self-Test Script for FailZero from Krang
# Performs bait interaction + pulls Cowrie logs from FailZero for analysis

TARGET="$1"
SSH_USER="doc"   # The remote user on FailZero (must be able to sudo or access Cowrie logs)
REMOTE_LOG="/home/cowrie/cowrie/var/log/cowrie/cowrie.log"
LOCAL_DIR="root/honeypot_logs"
LOCAL_LOG="$LOCAL_DIR/$(date +%Y-%m-%d_%H-%M-%S)_cowrie.log"
PORT=22
USERNAME="root"
TESTFILE="/opt/genesis/krang_config.yaml"

if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 <failzero_ip_or_hostname>"
  exit 1
fi

mkdir -p "$LOCAL_DIR"

echo "🕵️  Starting honeypot self-test against $TARGET"

echo -e "\n[1/6] Scanning TCP port 22..."
nmap -p $PORT "$TARGET" | grep "$PORT"

echo -e "\n[2/6] Attempting SSH login to Cowrie..."
timeout 5s ssh -o StrictHostKeyChecking=no -p $PORT "$USERNAME@$TARGET" "echo test" || echo "(expected fake shell or timeout)"

echo -e "\n[3/6] Running fake commands to trigger logs..."
timeout 5s ssh -o StrictHostKeyChecking=no -p $PORT "$USERNAME@$TARGET" "ls /; cat $TESTFILE; exit" || echo "(command simulation complete)"

echo -e "\n[4/6] Pulling Cowrie logs back to Krang..."
scp "$SSH_USER@$TARGET:$REMOTE_LOG" "$LOCAL_LOG" >/dev/null 2>&1

if [[ $? -eq 0 ]]; then
  echo "✅ Pulled Cowrie log to $LOCAL_LOG"
else
  echo "❌ Failed to retrieve Cowrie log. Check SSH user or path."
fi

echo -e "\n[5/6] Preview of last 5 log entries:"
tail -n 5 "$LOCAL_LOG" 2>/dev/null || echo "(log file not found or unreadable)"

echo -e "\n[6/6] Final port check:"
nmap -p $PORT "$TARGET" | grep "$PORT"

echo -e "\n🏁 Honeypot self-test complete."
