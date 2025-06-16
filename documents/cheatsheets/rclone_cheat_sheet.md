# 📘 Rclone Command Cheat Sheet

## ⚙️ Configuration

### Launch Configuration Wizard
```bash
rclone config
```

### Show Current Config
```bash
rclone config show
```

### List Remotes
```bash
rclone listremotes
```

## 📁 Basic File Operations

### Copy Files
```bash
rclone copy source:path dest:path
```

### Sync Files
```bash
rclone sync source:path dest:path
```

### Move Files
```bash
rclone move source:path dest:path
```

### Delete Files or Dirs
```bash
rclone delete remote:path
rclone purge remote:path   # Delete entire path
```

### Check Differences
```bash
rclone check source:path dest:path
```

## 🔍 Listing and Info

### List Directory
```bash
rclone ls remote:path
rclone lsd remote:path     # List only directories
rclone lsl remote:path     # Long list with size and modification time
```

### Tree View
```bash
rclone tree remote:path
```

### File Size and Count
```bash
rclone size remote:path
```

## 📦 Mounting

### Mount Remote (Linux/macOS)
```bash
rclone mount remote:path /mnt/mountpoint
```

### Mount with Aggressive Caching (Windows)
```bash
rclone mount remote:path X: \
  --vfs-cache-mode full \
  --cache-dir C:\path\to\cache \
  --vfs-cache-max-size 100G \
  --vfs-read-chunk-size 512M \
  --vfs-read-ahead 1G
```

## 🔁 Sync with Filtering

### Include / Exclude Files
```bash
rclone sync source:path dest:path --exclude "*.tmp"
rclone sync source:path dest:path --include "*.jpg"
```

## 📄 Logging and Dry Runs

### Verbose and Dry Run
```bash
rclone sync source:path dest:path -v --dry-run
```

### Log to File
```bash
rclone sync source:path dest:path --log-file=rclone.log -v
```

## 📡 Remote Control (RC)

### Start RC Server
```bash
rclone rcd --rc-web-gui
```

### Use RC Command
```bash
rclone rc core/stats
rclone rc vfs/stats
```

## 🛠️ Miscellaneous

### Serve Over HTTP/WebDAV/SFTP
```bash
rclone serve http remote:path
rclone serve webdav remote:path
rclone serve sftp remote:path
```

### Crypt Operations
```bash
rclone config create secure crypt remote:path
```

---

> ✅ **Tip**: Always use `--dry-run` when testing `sync`, `move`, or `delete` to prevent accidental data loss.
