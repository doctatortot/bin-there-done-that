# Server Naming Convention

To reduce confusion and improve clarity, we follow a clear and themed naming structure.

## Naming Style

Examples:

- `krang.internal` – Master backend server
- `replica.db3.sshjunkie.com` – Staging PostgreSQL replica
- `shredderv2` – ZFS backup server
- `anthony` – Ansible control node
- `nexus` – Main ZFS pool server for assets

## Guidelines

- Avoid generic names (`server1`, `host123`)
- Use themed names (e.g., TMNT characters for core infrastructure)
- Include environment tags where needed (`-test`, `-prod`)
