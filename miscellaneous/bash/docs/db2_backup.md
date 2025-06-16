---
title: db2_backup.sh
categories: [backup]
source: bin/db2_backup.sh
generated: 2025-05-22T08:38:59-04:00
---

# db2_backup.sh

#!/bin/bash
#
Script Name: db2_zfs_backup.sh
Description: Creates a raw base backup of PostgreSQL on zcluster.technodrome2 using pg_basebackup in directory mode.
             Transfers the backup to The Vault’s ZFS dataset and snapshots it for long-term retention.
Requirements: pg_basebackup, SSH access, rclone or rsync, ZFS dataset available at destination
Usage: ./db2_zfs_backup.sh
Author: Doc @ Genesis Ops
Date: 2025-05-12
#
### CONFIGURATION ###
Remote source rclone config (optional)

_Auto-generated from source script on Thu May 22 08:38:59 AM EDT 2025_
