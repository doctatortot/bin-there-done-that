import os
import paramiko
import requests
from datetime import datetime
from collections import defaultdict

# === CONFIG ===
NODES = {
    "shredderv2": {"host": "shredderv2.sshjunkie.com", "user": "doc"},
    "thevault": {"host": "209.209.9.128", "user": "doc"},
    "technodrome1": {"host": "38.102.127.165", "user": "doc"},
    "technodrome2": {"host": "38.102.127.166", "user": "doc"},
}

SSH_KEY = "~/.ssh/genesis_healthcheck"
ZFS_CMD = "zfs list -t snapshot -o name,creation -s creation"

# === TELEGRAM CONFIG ===
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""

def send_to_telegram(message):
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    data = {
        "chat_id": TELEGRAM_CHAT_ID,
        "text": message,
        "parse_mode": "Markdown"
    }
    try:
        requests.post(url, data=data, timeout=10)
    except Exception as e:
        print(f"Telegram send failed: {e}")

def ssh_run(host, user, cmd):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(hostname=host, username=user, key_filename=os.path.expanduser(SSH_KEY), timeout=10)
    stdin, stdout, stderr = ssh.exec_command(cmd)
    out = stdout.read().decode().strip()
    ssh.close()
    return out

def parse_snapshot_output(output):
    lines = output.strip().split("\n")[1:]  # skip header
    snaps = defaultdict(list)

    for line in lines:
        try:
            name, creation = line.strip().split(None, 1)
            dataset, _ = name.split("@")
            dt = datetime.strptime(creation.strip(), "%a %b %d %H:%M %Y")
            snaps[dataset].append(dt)
        except Exception:
            continue
    return snaps

def summarize(node_name, dataset_snaps):
    if not dataset_snaps:
        send_to_telegram(f"⚠️ *No snapshots found* on `{node_name}`")
        return

    msg = [f"📦 *ZFS Snapshot Report — {node_name}*"]
    for dataset, times in sorted(dataset_snaps.items()):
        age = (datetime.now() - max(times)).total_seconds() / 3600
        msg.append(
            f"*{dataset}*\n"
            f"- Count: {len(times)}\n"
            f"- Oldest: {min(times)}\n"
            f"- Newest: {max(times)}\n"
            f"- Recent age: {age:.2f}h\n"
        )
    send_to_telegram("\n".join(msg))

if __name__ == "__main__":
    for name, node in NODES.items():
        try:
            output = ssh_run(node["host"], node["user"], ZFS_CMD)
            data = parse_snapshot_output(output)
            summarize(name.upper(), data)
        except Exception as e:
            send_to_telegram(f"❌ Failed to check `{name}`: {e}")
