#!/bin/bash
# list_installed_tools.sh
# Summarizes the most recent Genesis tools installation log

LOG_FILE="$(dirname "$0")/setup_install.log"

if [[ ! -f "$LOG_FILE" ]]; then
  echo "No installation log found at \$LOG_FILE"
  exit 1
fi

echo "📋 Installed Genesis Tools (from \$LOG_FILE):"
echo "--------------------------------------------------"
grep "\[INSTALL\]" "$LOG_FILE" | sed 's/\[INSTALL\] //' | sort
