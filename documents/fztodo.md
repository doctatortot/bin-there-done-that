FailZero TODO List
✅ Completed

fz_ip_validator.py runs on Krang with systemd and venv

Logging to /var/log/failzero/ip_validator.log

IP abuse detection via /validate endpoint

PayPal billing form with terminal-style UI

Telegram alerts on order

Abuse watcher with threshold-based disable

genesisctl disable --ip blocks outbound traffic

    Screen-based background runner (genesisctl watch-abuse)

🧠 Next Steps (Active TODO List)
🔒 Abuse Management

Build /api/report endpoint to manually flag IPs from Krang or external tools

Switch abuse_list in fz_ip_validator.py to file-based or Redis-backed source

    Log confirmed abuse incidents to /var/log/genesis-abuse-confirmed.log

🌐 Frontend Integration

Modify billing HTML to call /validate before starting PayPal process

Display an error if IP is flagged (valid === false) and block purchase

    Show dynamic pricing and risk flags in the form using the validator output

💳 Billing + Provision

Hook PayPal IPN or success return URL to trigger VPS creation

Match PayPal TXID to IP + label and log it

Generate reverse DNS automatically on provision (e.g., nighthawk01.failzero.net)

    Add /privacy and /terms static pages to keep things legally clean

⚙️ Tooling & UX

Add genesisctl enable --ip to unblock previously flagged IPs

Add genesisctl status --ip to query abuse hits / log activity

    Optionally hash or sign each VPS order for non-repudiation audit trail

🧪 Optional / Nice-to-Have

Build a minimal dashboard or log viewer for flagged IPs

Rate-limit /validate via nginx or Flask limiter

Replace all external IP tools with internal validator
