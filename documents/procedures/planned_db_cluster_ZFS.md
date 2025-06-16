# 🗺️ PostgreSQL High-Availability Architecture with ZFS (Genesis Hosting)

```plaintext
                ┌──────────────────────────────┐
                │        Client Applications   │
                └────────────┬─────────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │    HAProxy      │
                    │ (Load Balancer) │
                    └────────┬────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
                ▼                         ▼
        ┌──────────────┐           ┌──────────────┐
        │ Primary Node │           │ Replica Node │
        │  (DB Server) │           │  (DB Server) │
        └──────┬───────┘           └──────┬───────┘
               │                          │
               ▼                          ▼
        ┌──────────────┐           ┌──────────────┐
        │ ZFS Storage  │           │ ZFS Storage  │
        │  (RAIDZ1)    │           │  (RAIDZ1)    │
        └──────────────┘           └──────────────┘
               │                          │
               └────────┬────────┬────────┘
                        │        │
                        ▼        ▼
                 ┌──────────────┐
                 │  Backup Node │
                 │ (ZFS RAIDZ1) │
                 └──────────────┘
