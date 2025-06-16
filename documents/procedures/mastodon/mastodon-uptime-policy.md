# Mastodon Uptime Policy

Genesis Hosting Technologies strives to maintain high availability for our Mastodon instance at **chatwithus.live**.

## Availability Target

- **Uptime Goal**: 99.5% monthly (approx. 3.5 hours of downtime max)
- We consider chatwithus.live "unavailable" when:
  - The web UI fails to load or times out
  - Toot delivery is delayed by >10 minutes
  - Federation is broken for more than 30 minutes

## Redundancy

- PostgreSQL cluster with HA failover
- Redis and Sidekiq monitored 24/7
- Mastodon is backed by ZFS storage and hourly snapshots

## Exceptions

- Scheduled maintenance (see Maintenance Policy)
- DDoS or external platform failures (e.g., relay outages)
