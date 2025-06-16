#!/bin/bash

# Database configuration
DB_HOST="db4.genesishostingtechnologies.com"
DB_NAME="sms_app"
DB_USER="sms_user"
DB_PASS="rusty2281"

# Log file location
LOG_FILE="$HOME/db_clear.log"

# Export the password so psql can use it
export PGPASSWORD=$DB_PASS

# Function to clear a table
clear_table() {
    local table_name=$1
    echo "Clearing table: $table_name"
    psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "DELETE FROM $table_name;" 2>&1 | tee -a $LOG_FILE
    if [ $? -eq 0 ]; then
        echo "Table $table_name cleared successfully"
    else
        echo "Error clearing table $table_name" >&2
    fi
}

# Uncomment the following line to clear the users table
#clear_table "users"
clear_table "messages"

# Unset the password
unset PGPASSWORD

echo "Script execution completed"
