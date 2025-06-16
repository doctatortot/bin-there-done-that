# Genesis Shield – Security & Threat Monitoring

Genesis Shield is our custom-built alert and ban system, integrated across our infrastructure.

## Features

- Aggregates Fail2Ban logs across all VMs
- Bans pushed in real-time via Mastodon DM and Telegram
- Scripts track:
  - Repeated SSH failures
  - API abuse
  - Web panel brute force attempts

## Interfaces

- Terminal dashboard for live bans/unbans
- Role-based control (root/admin only)
- Daily threat summary via Mastodon bot

## Roadmap

- WHMCS integration for abuse tickets
- Live threat map by country/IP
- REST API for admin toolkit
