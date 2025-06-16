# 📘 ZFS Command Cheat Sheet

## 🛠️ Pool Management

### Create a Pool
```bash
zpool create <poolname> <device>
zpool create <poolname> mirror <dev1> <dev2>
zpool create <poolname> raidz1 <dev1> <dev2> <dev3> ...
```

### List Pools
```bash
zpool list
```

### Destroy a Pool
```bash
zpool destroy <poolname>
```

### Add Devices to a Pool
```bash
zpool add <poolname> <device>
```

### Export / Import Pool
```bash
zpool export <poolname>
zpool import <poolname>
zpool import -d /dev/disk/by-id <poolname>
```

## 🔍 Pool Status and Health

### Check Pool Status
```bash
zpool status
zpool status -v
```

### Scrub a Pool
```bash
zpool scrub <poolname>
```

### Clear Errors
```bash
zpool clear <poolname>
```

## 🧱 Dataset Management

### Create a Dataset
```bash
zfs create <poolname>/<dataset>
```

### List Datasets
```bash
zfs list
zfs list -t all
```

### Destroy a Dataset
```bash
zfs destroy <poolname>/<dataset>
```

## 📦 Mounting and Properties

### Set Mount Point
```bash
zfs set mountpoint=/your/path <poolname>/<dataset>
```

### Mount / Unmount
```bash
zfs mount <dataset>
zfs unmount <dataset>
```

### Auto Mount
```bash
zfs set canmount=on|off|noauto <dataset>
```

## 📝 Snapshots & Clones

### Create a Snapshot
```bash
zfs snapshot <poolname>/<dataset>@<snapshotname>
```

### List Snapshots
```bash
zfs list -t snapshot
```

### Roll Back to Snapshot
```bash
zfs rollback <poolname>/<dataset>@<snapshotname>
```

### Destroy a Snapshot
```bash
zfs destroy <poolname>/<dataset>@<snapshotname>
```

### Clone a Snapshot
```bash
zfs clone <poolname>/<dataset>@<snapshot> <poolname>/<new-dataset>
```

## 🔁 Sending & Receiving

### Send Snapshot to File or Pipe
```bash
zfs send <snapshot> > file
zfs send -R <snapshot> | zfs receive <pool>/<dataset>
```

### Receive Snapshot
```bash
zfs receive <pool>/<dataset>
```

## 🧮 Useful Info & Tuning

### Check Available Space
```bash
zfs list
```

### Set Quota or Reservation
```bash
zfs set quota=10G <dataset>
zfs set reservation=5G <dataset>
```

### Enable Compression
```bash
zfs set compression=lz4 <dataset>
```

### Enable Deduplication (use cautiously)
```bash
zfs set dedup=on <dataset>
```

---

> ✅ **Tip**: Always test ZFS commands in a safe environment before using them on production systems!
