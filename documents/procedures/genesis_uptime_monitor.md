# Genesis Uptime Monitor

This package sets up a simple service uptime tracker on your local server (e.g., Krang). It includes:

- A Python Flask API to report 24-hour uptime
- A bash script to log uptime results every 5 minutes
- A systemd unit to keep the API running

## Setup Instructions

### 1. Install Requirements

```bash
sudo apt install python3-venv curl
cd ~
python3 -m venv genesis_api
source genesis_api/bin/activate
pip install flask
```

### 2. Place Files

- `uptime_server.py` → `/home/doc/uptime_server.py`
- `genesis_check.sh` → `/usr/local/bin/genesis_check.sh` (make it executable)
- `genesis_uptime_api.service` → `/etc/systemd/system/genesis_uptime_api.service`

### 3. Enable Cron

Edit your crontab with `crontab -e` and add:

```cron
*/5 * * * * /usr/local/bin/genesis_check.sh
```

### 4. Start API Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now genesis_uptime_api
```

Then browse to `http://localhost:5000/api/uptime/radio`

## Web Integration

In your HTML, add a div and script like this:

```html
<div id="radioUptime"><small>Uptime: Loading…</small></div>
<script>
fetch('/api/uptime/radio')
  .then(r => r.json())
  .then(data => {
    document.getElementById('radioUptime').innerHTML = `<small>Uptime: ${data.uptime}% (24h)</small>`;
  });
</script>
```
