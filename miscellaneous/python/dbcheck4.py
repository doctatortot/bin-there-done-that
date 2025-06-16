import subprocess
import os
import requests
import datetime
import paramiko
import time
import psycopg2

# ==== CONFIG ====
MASTODON_INSTANCE = "https://chatwithus.live"
MASTODON_TOKEN = "rimxBLi-eaJAcwagkmoj6UoW7Lc473tQY0cOM041Euw"
MASTODON_USER_ID = "114386383616633367"
HEALTHCHECK_HTML = "/var/www/html/healthcheck.html"
ARCHIVE_DIR = "/home/doc/genesis-tools/archive.html"

DISK_WARN_THRESHOLD = 10
LOG_FILES = ["/var/log/syslog", "/var/log/nginx/error.log"]
LOG_PATTERNS = ["ERROR", "FATAL", "disk full", "out of memory"]
SUPPRESSED_PATTERNS = ["SomeKnownHarmlessMastodonError"]

NODES = [
    {"name": "shredder", "host": "38.102.127.172", "ssh_user": "doc", "services": ["minio.service"], "disks": ["/", "/mnt/miniodata"], "db": False, "raid": True},
    {"name": "mastodon", "host": "chatwithus.live", "ssh_user": "root", "services": ["nginx", "mastodon-web"], "disks": ["/"], "db": False, "raid": False},
    {"name": "db1", "host": "zcluster.technodrome1.sshjunkie.com", "ssh_user": "doc", "services": ["postgresql@16-main.service"], "disks": ["/", "/var/lib/postgresql"], "db": True, "raid": True},
    {"name": "db2", "host": "zcluster.technodrome2.sshjunkie.com", "ssh_user": "doc", "services": ["postgresql@16-main.service"], "disks": ["/", "/var/lib/postgresql"], "db": True, "raid": True}
]

# ==== Mastodon DM ====
def mastodon_dm(message, retries=3):
    url = f"{MASTODON_INSTANCE}/api/v1/statuses"
    headers = {"Authorization": f"Bearer {MASTODON_TOKEN}"}
    payload = {"status": message, "visibility": "direct", "in_reply_to_account_id": MASTODON_USER_ID}
    for attempt in range(retries):
        try:
            resp = requests.post(url, headers=headers, data=payload)
            if resp.status_code == 200:
                return
            print(f"Failed to send Mastodon DM (attempt {attempt+1}): {resp.text}")
        except Exception as e:
            print(f"Error sending Mastodon DM: {e}")
        time.sleep(5)

# ==== SSH Helper ====
def ssh_command(host, user, cmd):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(hostname=host, username=user, timeout=10)
        stdin, stdout, stderr = ssh.exec_command(cmd)
        out = stdout.read().decode().strip()
        err = stderr.read().decode().strip()
        if "Authentication failed" in out or "permission denied" in out.lower() or "permission denied" in err.lower():
            stdin, stdout, stderr = ssh.exec_command(f"sudo {cmd}")
            out = stdout.read().decode().strip()
        ssh.close()
        return out
    except Exception as e:
        return f"SSH error: {e}"

SERVICE_PROCESS_MAP = {
    "minio.service": "minio",
    "postgresql@16-main.service": "postgres",
    "mastodon-web": "puma"
}

def check_remote_service(host, user, service, node_name):
    try:
        process_name = SERVICE_PROCESS_MAP.get(service, service)
        cmd = f"pgrep -f '{process_name}'"
        out = ssh_command(host, user, cmd)
        if not out.strip():
            return f"[{node_name}] CRITICAL: Service {service} not running! (pgrep '{process_name}' found nothing)"
    except Exception as e:
        return f"[{node_name}] ERROR: Service check failed: {e}"
    return None

def choose_emoji(line):
    if "RAID" in line:
        if "disk" in line.lower():
            return "\U0001F4C8"
    if "rclone" in line.lower():
        return "\U0001F422"
    if "Service" in line:
        return "\U0001F6D1"
    if "Replication" in line:
        return "\U0001F4A5"
    return "\u26A0\uFE0F"

def check_remote_disk(host, user, path, node_name):
    try:
        cmd = f"df --output=pcent {path} | tail -1 | tr -dc '0-9'"
        out = ssh_command(host, user, cmd)
        if not out:
            return f"[{node_name}] ERROR: Disk {path} not found or could not check disk usage."
        percent = int(out)
        if percent > (100 - DISK_WARN_THRESHOLD):
            return f"[{node_name}] WARNING: Only {100 - percent}% disk free on {path}."
    except Exception as e:
        return f"[{node_name}] ERROR: Disk check failed: {e}"
    return None

def check_remote_logs(host, user, node_name):
    alerts = []
    for log in LOG_FILES:
        cmd = f"tail -500 {log}"
        try:
            out = ssh_command(host, user, cmd)
            lines = out.split("\n")
            for pattern in LOG_PATTERNS:
                if any(pattern in line and not any(s in line for s in SUPPRESSED_PATTERNS) for line in lines):
                    alerts.append(f"[{node_name}] WARNING: Pattern '{pattern}' found in {log}")
        except Exception as e:
            alerts.append(f"[{node_name}] ERROR: Could not read log {log}: {e}")
    return alerts

# === MAIN CALL ===
if __name__ == "__main__":
    print("Genesis Healthcheck started...")
    critical_problems = []
    warning_problems = []

    for node in NODES:
        print(f"Checking node: {node['name']} @ {node['host']}")
        for disk in node['disks']:
            result = check_remote_disk(node['host'], node['ssh_user'], disk, node['name'])
            if result:
                print(result)
                if "CRITICAL" in result:
                    critical_problems.append(result)
                else:
                    warning_problems.append(result)

        for service in node['services']:
            result = check_remote_service(node['host'], node['ssh_user'], service, node['name'])
            if result:
                print(result)
                if "CRITICAL" in result:
                    critical_problems.append(result)
                else:
                    warning_problems.append(result)

        logs = check_remote_logs(node['host'], node['ssh_user'], node['name'])
        for log in logs:
            print(log)
            warning_problems.append(log)

    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    if critical_problems:
        msg_lines = [
            f"🚨 Genesis Radio Critical Healthcheck {now} 🚨",
            f"⚡ {len(critical_problems)} critical issues found:"
        ]
        msg_lines.extend(f"- {choose_emoji(p)} {p}" for p in critical_problems)
        mastodon_dm("\n".join(msg_lines))

    if warning_problems:
        msg_lines = [
            f"⚠️ Genesis Radio Warning Healthcheck {now} ⚠️",
            f"⚡ {len(warning_problems)} warnings found:"
        ]
        msg_lines.extend(f"- {choose_emoji(p)} {p}" for p in warning_problems)
        mastodon_dm("\n".join(msg_lines))

    if not critical_problems and not warning_problems:
        mastodon_dm(f"✅ Genesis Radio Healthcheck {now}: All systems normal.")
