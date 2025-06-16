# Monitoring Setup

We use a layered monitoring approach to ensure full visibility and rapid response.

## Stack

- **Prometheus** for metrics collection
- **Grafana** for visualization dashboards
- **Fail2Ban** for intrusion attempts
- **Genesis Shield** for aggregated alerts (Telegram + Mastodon)

## What We Monitor

| System         | Metric Examples                           |
|----------------|--------------------------------------------|
| PostgreSQL     | Replication lag, disk usage, active queries |
| Web Servers    | HTTP response time, TLS errors             |
| MinIO / Assets | Cache hit ratio, sync status               |
| Docker Hosts   | Container uptime, memory pressure          |

## Alerting

- Telegram: Real-time infra alerts
- Mastodon bot: Daily summaries and status posts
- Fallback email alerts for critical failures
