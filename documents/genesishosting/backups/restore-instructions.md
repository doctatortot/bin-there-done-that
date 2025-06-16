# Restore Instructions

The following steps outline how to restore data for each supported service.

## DirectAdmin

1. Access DA panel as admin
2. Go to Admin Backup/Transfer
3. Select user and backup date
4. Click "Restore"

## WHMCS

1. SSH into WHMCS server
2. Restore from encrypted MySQL dump
3. Restart `php-fpm` and `nginx`

## AzuraCast

1. Stop all Docker containers
2. Replace `station_data` and `config` volumes
3. Restart stack via `docker-compose up -d`

## TeamTalk

1. Replace configuration file (`tt5srv.xml`)
2. Restart TeamTalk server

## VM-Level Restore (ZFS)

1. `zfs rollback poolname/dataset@snapshotname`
2. Verify service health and logs
