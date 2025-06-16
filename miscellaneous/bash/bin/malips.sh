#!/bin/bash

# Path to Snort's alert log (snort.alert.fast)
SNORT_LOG="/var/log/snort/snort.alert.fast"

# Database connection details
DB_HOST="zcluster.technodrome1.sshjunkie.com"
DB_USER="ipblocks_user"
DB_PASS="rusty2281"
DB_NAME="ipblocks"

# Function to insert blocked IP into the PostgreSQL database
block_ip() {
    local ip=$1

    # Remove port if included in the IP
    ip=${ip%%:*}

    # Insert the blocked IP into the PostgreSQL database (into the blocked_ip_log table)
    PGPASSWORD="$DB_PASS" psql -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" -c "INSERT INTO blocked_ip_log (ip_address) VALUES ('$ip');"

    # Optionally print to confirm the insertion
    echo "Blocked IP $ip inserted into the database log."
}

# Ensure the log file exists and is readable
if [ ! -f "$SNORT_LOG" ]; then
    echo "Snort log file not found!"
    exit 1
fi

# Monitor the snort.alert.fast file for new malicious IPs
tail -F "$SNORT_LOG" | while read line; do
    # Debug: Output the full line from Snort log
    echo "Processing: $line"

    # Extract source and destination IP addresses from Snort logs
    if echo "$line" | grep -q "ICMP PING NMAP"; then
        # Extract source IP (before "->")
        ip=$(echo "$line" | awk -F' -> ' '{print $1}' | awk '{print $NF}' | cut -d':' -f1)
        echo "Found Source IP: $ip"  # Debug: Show the IP being extracted
        block_ip "$ip"
    elif echo "$line" | grep -q "EXPLOIT"; then
        # Extract source IP (before "->")
        ip=$(echo "$line" | awk -F' -> ' '{print $1}' | awk '{print $NF}' | cut -d':' -f1)
        echo "Found Source IP: $ip"  # Debug: Show the IP being extracted
        block_ip "$ip"
    fi
done
