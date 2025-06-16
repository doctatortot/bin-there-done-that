# Genesis Radio Internal Architecture Map

---

## 🏢 Core Infrastructure

| System | Purpose | Location |
|:---|:---|:---|
| Krang | Main admin server / script runner / monitoring node | On-premises / VM |
| SPL Server (Windows) | StationPlaylist Studio automation and playout system | On-premises / VM |
| Shredder | MinIO Object Storage / Cache server | On-premises / VM |
| PostgreSQL Cluster (db1/db2) | Mastodon database backend / Other app storage | Clustered VMs |
| Mastodon Server | Frontend social interface for alerts, community | Hosted at `chatwithus.live` |

---

## 🧠 Automation Components

| Component | Description | Hosted Where |
|:---|:---|:---|
| `mount_guardian.ps1` | Automatically ensures Rclone mounts (Q:\ and R:\) are up | SPL Server (Windows) |
| `rotate_mount_logs.ps1` | Weekly log rotation for mount logs | SPL Server (Windows) |
| `healthcheck.py` | Multi-node health and service monitor | Krang |
| Mastodon DM Alerts | Immediate alerting if something breaks (Mounts, Services) | Krang via API |
| Genesis Mission Control Landing Page | Web dashboard with Commandments + Live Healthcheck | Hosted on Krang's Nginx |

---

## 🎙️ Storage and Streaming

| Mount | Purpose | Backed by |
|:---|:---|:---|
| Q:\ (Assets) | Station IDs, sweepers, intro/outros, promos | GenesisAssets Bucket (Rclone) |
| R:\ (Library) | Full music library content | GenesisLibrary Bucket (Rclone) |

✅ Primary Cache: `L:\` (SSD)  
✅ Secondary Cache: `X:\` (Spinning HDD)

---

## 📡 Communications

| Alert Type | How Sent |
|:---|:---|
| Mount Failures | Direct Mastodon DM |
| Healthcheck Failures (Disk, Service, SMART, RAID) | Direct Mastodon DM |
| Git Push Auto-Retry Failures (optional future upgrade) | Potential Mastodon DM |

---

## 📋 GitOps Flow

| Step | Script | Behavior |
|:---|:---|:---|
| Save changes | giteapush.sh | Auto stage, commit (timestamped), push to Gitea |
| Retry failed push | giteapush.sh auto-retry block | Up to 3x tries with 5-second gaps |
| Repo status summary | giteapush.sh final step | Clean `git status -sb` displayed |

✅ Follows GROWL commit style:  
Good, Readable, Obvious, Well-Scoped, Logical.

---

## 📜 Policies and Procedures

| Document | Purpose |
|:---|:---|
| `OPS.md` | Healthcheck Runbook and Service Recovery Instructions |
| `GROWL.md` | Git Commit Message Style Guide |
| `Mission Control Landing Page` | Browser homepage with live dashboard + ops philosophy |

---

## 🛡️ Key Principles

- Calm is Contagious.
- Go Slow to Go Fast.
- Snappy Snaps Save Lives.
- Scripts are Smarter Than Sleepy Admins.
- If You Didn't Write It Down, It Didn't Happen.

---

# 🎙️ Genesis Radio Ops  
Built with pride. Built to last. 🛡️🚀
