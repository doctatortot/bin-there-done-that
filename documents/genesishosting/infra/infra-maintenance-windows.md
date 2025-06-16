# Maintenance Window Policy

To maintain consistency and reduce customer impact, we adhere to a strict maintenance schedule.

## Standard Window

- **Every Sunday, 7 PM – 9 PM Eastern**
- Non-emergency changes must occur during this window

## What’s Allowed

- OS & kernel updates
- Docker/image upgrades
- ZFS snapshots & cleanup
- Rolling restarts of containers

## Emergencies

- Critical security patches can bypass the window
- All emergency changes must be logged and reviewed

## Notifications

- Posted on Mastodon at least 1 hour before the window begins
- Clients notified via WHMCS if it will affect their service
