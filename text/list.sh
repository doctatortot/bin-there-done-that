#!/bin/bash

# Database connection parameters
DB_NAME="sms_app"
DB_USER="sms_user"  # replace with your PostgreSQL username
DB_HOST="db3.cluster.genesishostingtechnologies.com"  # or the address of your PostgreSQL server
DB_PORT="5432"  # default PostgreSQL port
DB_PASS="rusty2281"

export PGPASSWORD=$DB_PASS

# Execute the query
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT * FROM messages;"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT * FROM blocked_numbers;"
unset PGPASSWORD
