# Logging & Monitoring Policy

We collect and monitor system activity to detect threats, enforce accountability, and assist in incident resolution.

## Log Types

- SSH login attempts
- WHMCS access logs
- AzuraCast and TeamTalk server logs
- PostgreSQL query and connection logs
- Fail2Ban logs (ban/unban events)

## Monitoring Tools

- Prometheus for metrics
- Grafana dashboards for visual alerts
- Genesis Shield (Telegram + Mastodon alerting)
- Manual log review every 7 days

## Retention

- General logs: 30 days
- Security-related logs: 90 days minimum
- Logs archived to encrypted ZFS volume
