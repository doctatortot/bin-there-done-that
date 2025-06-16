# Mastodon Maintenance Policy

We adhere to structured maintenance windows for **chatwithus.live** to ensure reliability without disrupting users.

## Weekly Maintenance

- **Window**: Sundays, 7 PM – 9 PM Eastern Time
- Routine updates (OS, Docker images, dependencies)
- Asset rebuilds, minor database tune-ups

## Emergency Maintenance

- Patching vulnerabilities (e.g., CVEs)
- Redis/PostgreSQL crash recovery
- Federation or relay failures

## Notifications

- Posted to Mastodon via @administration at least 1 hour in advance
- Maintenance announcements also pushed to the server status page

## Failures During Maintenance

- If the instance does not recover within 30 minutes, full rollback initiated
