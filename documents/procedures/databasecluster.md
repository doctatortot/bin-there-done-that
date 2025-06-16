# Database Cluster (baboon.sshjunkie.com)

## Overview
The database cluster consists of two PostgreSQL database servers hosted on `baboon.sshjunkie.com`. These servers are used to store data for services such as Mastodon and AzuraCast. The cluster ensures high availability and fault tolerance through replication and backup strategies.

## Installation
Install PostgreSQL on both nodes in the cluster:

```bash
# Update package list and install PostgreSQL
sudo apt update
sudo apt install -y postgresql postgresql-contrib

# Ensure PostgreSQL is running
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

## Configuration
### PostgreSQL Configuration Files:
- **pg_hba.conf**:
  - Allow replication and local connections.
  - Example:
    ```ini
    local   all             postgres                                md5
    host    replication     all             192.168.0.0/16            md5
    ```
- **postgresql.conf**:
  - Set `wal_level` for replication:
    ```ini
    wal_level = hot_standby
    max_wal_senders = 3
    ```

### Replication Configuration:
- Set up streaming replication between the two nodes (`baboon.sshjunkie.com` as the master and the second node as the replica).

1. On the master node, enable replication and restart PostgreSQL.
2. On the replica node, set up replication by copying the data directory from the master node and configure the `recovery.conf` file.

Example `recovery.conf` on the replica:
```ini
standby_mode = on
primary_conninfo = 'host=baboon.sshjunkie.com port=5432 user=replicator password=your_password'
trigger_file = '/tmp/postgresql.trigger.5432'
```

## Usage
- **Check the status of PostgreSQL**:
  ```bash
  sudo systemctl status postgresql
  ```

- **Promote the replica to master**:
  ```bash
  pg_ctl promote -D /var/lib/postgresql/data
  ```

## Backups
Use `pg_basebackup` to create full backups of the cluster. Example:

```bash
pg_basebackup -h baboon.sshjunkie.com -U replicator -D /backups/db_backup -Ft -z -P
```

Automate backups with cronjobs for regular snapshots.

## Troubleshooting
- **Issue**: Replica is lagging behind.
  - **Solution**: Check network connectivity and ensure the replica is able to connect to the master node. Monitor replication lag with:
    ```bash
    SELECT * FROM pg_stat_replication;
    ```

## Monitoring
- **Monitor replication status**:
  ```bash
  SELECT * FROM pg_stat_replication;
  ```

- **Monitor database health**:
  ```bash
  pg_isready
  ```

## Additional Information
- [PostgreSQL Streaming Replication Documentation](https://www.postgresql.org/docs/current/warm-standby.html)
