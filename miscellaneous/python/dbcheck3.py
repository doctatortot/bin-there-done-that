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

SUDO_PASSWORD = 'rusty2281'

DISK_WARN_THRESHOLD = 10
INODE_WARN_THRESHOLD = 10
LOG_FILES = ["/var/log/syslog", "/var/log/nginx/error.log"]
LOG_PATTERNS = ["ERROR", "FATAL", "disk full", "out of memory"]
SUPPRESSED_PATTERNS = ["SomeKnownHarmlessMastodonError"]

NODES = [
    {"name": "shredder", "host": "38.102.127.172", "ssh_user": "doc", "services": ["minio.service"], "disks": ["/", "/mnt/raid5"], "db": False, "raid": True},
    {"name": "mastodon", "host": "chatwithus.live", "ssh_user": "root", "services": ["nginx", "mastodon-web"], "disks": ["/"], "db": False, "raid": False},
    {"name": "db1", "host": "zcluster.technodrome1.sshjunkie.com", "ssh_user": "doc", "services": ["postgresql@16-main.service"], "disks": ["/", "/var/lib/postgresql"], "db": True, "raid": True},
    {"name": "db2", "host": "zcluster.technodrome1.sshjunkie.com", "ssh_user": "doc", "services": ["postgresql@16-main.service"], "disks": ["/", "/var/lib/postgresql"], "db": True, "raid": True}
]

def mastodon_dm(message, retries=3):
    url = f"{MASTODON_INSTANCE}/api/v1/statuses"
    headers = {"Authorization": f"Bearer {MASTODON_TOKEN}"}
    payload = {"status": message, "visibility": "direct", "in_reply_to_account_id": MASTODON_USER_ID}
    for attempt in range(retries):
        try:
            resp = requests.post(url, headers=headers, data=payload, timeout=10)
            if resp.status_code == 200:
                return
            print(f"Failed to send Mastodon DM (attempt {attempt+1}): {resp.text}")
        except Exception as e:
            print(f"Exception during Mastodon DM (attempt {attempt+1}): {e}")
        time.sleep(5)

def ssh_command(host, user, cmd):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(hostname=host, username=user, key_filename=os.path.expanduser("~/.ssh/genesis_healthcheck"), timeout=10)

    stdin, stdout, stderr = ssh.exec_command(cmd)
    out = stdout.read().decode().strip()
    err = stderr.read().decode().strip()

    if not out or "permission denied" in err.lower() or "sudo:" in err.lower():
        sudo_cmd = f"echo '{SUDO_PASSWORD}' | sudo -S {cmd}"
        stdin, stdout, stderr = ssh.exec_command(sudo_cmd)
        out = stdout.read().decode().strip()
        err = stderr.read().decode().strip()

    ssh.close()
    return out if out else err

def choose_emoji(line):
    if "RAID" in line:
        if "disk" in line.lower():
            return "📈"
    if "rclone" in line.lower():
        return "🐢"
    if "Service" in line:
        return "🚩"
    if "Replication" in line:
        return "💥"
    return "⚠️"

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

def check_remote_service(host, user, service, node_name):
    try:
        cmd = f"systemctl is-active {service}"
        out = ssh_command(host, user, cmd)
        if out.strip() != "active":
            return f"[{node_name}] CRITICAL: Service {service} not running!"
    except Exception as e:
        return f"[{node_name}] ERROR: Service check failed: {e}"
    return None

def check_replication(host, node_name):
    try:
        conn = psycopg2.connect(host=host, dbname="postgres", user="postgres", connect_timeout=5)
        cur = conn.cursor()
        cur.execute("SELECT pg_is_in_recovery();")
        is_replica = cur.fetchone()[0]
        if is_replica:
            cur.execute("SELECT EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp()))::INT;")
            lag = cur.fetchone()[0]
            if lag is None:
                return f"[{node_name}] CRITICAL: Standby not streaming! Replication down."
            elif lag >= 60:
                return f"[{node_name}] WARNING: Replication lag is {lag} seconds."
        cur.close()
        conn.close()
    except Exception as e:
        return f"[{node_name}] ERROR: Replication check failed: {e}"
    return None

def check_remote_raid_md0(host, user, node_name):
    alerts = []
    try:
        pools_output = ssh_command(host, user, "zpool list -H -o name")
        pool_names = pools_output.strip().splitlines()
        for pool in pool_names:
            health_cmd = f"zpool status -x {pool}"
            health_out = ssh_command(host, user, health_cmd)
            if f"pool '{pool}' is healthy" not in health_out.lower():
                alerts.append(f"[{node_name}] WARNING: ZFS pool '{pool}' is not healthy: {health_out.strip()}")

            snap_cmd = f"zfs list -t snapshot -o name,creation -s creation -H -r {pool}"
            snap_out = ssh_command(host, user, snap_cmd)
            if not snap_out.strip():
                alerts.append(f"[{node_name}] WARNING: No snapshots found in ZFS pool '{pool}'")
            else:
                last_snap = snap_out.strip().splitlines()[-1]
                snap_parts = last_snap.split("\t")
                if len(snap_parts) == 2:
                    snap_time_str = snap_parts[1].strip()
                    snap_time = datetime.datetime.strptime(snap_time_str, "%a %b %d %H:%M %Y")
                    delta = datetime.datetime.now() - snap_time
                    if delta.total_seconds() > 86400:
                        alerts.append(f"[{node_name}] WARNING: Last snapshot on pool '{pool}' is older than 24h: {snap_time_str}")
    except Exception as e:
        alerts.append(f"[{node_name}] ERROR: ZFS RAID check failed: {e}")
        try:
            mdstat = ssh_command(host, user, "cat /proc/mdstat")
            lines = mdstat.splitlines()
            status = None
            inside_md0 = False
            for line in lines:
                if line.startswith("md0"):
                    inside_md0 = True
                elif inside_md0:
                    if "[" in line and "]" in line:
                        status = line[line.index("["):line.index("]")+1]
                        break
                    if line.strip() == "" or ":" in line:
                        break
            if status is None:
                alerts.append(f"[{node_name}] CRITICAL: /dev/md0 RAID status string not found!")
            elif "_" in status:
                alerts.append(f"[{node_name}] WARNING: /dev/md0 RAID degraded! Status: {status}")
        except Exception as fallback_e:
            alerts.append(f"[{node_name}] ERROR: RAID check failed (ZFS+mdstat): {e}; {fallback_e}")
    return "\n".join(alerts) if alerts else None

def check_remote_logs(host, user, node_name):
    alerts = []
    for log in LOG_FILES:
        cmd = f"tail -500 {log}"
        try:
            out = ssh_command(host, user, cmd)
            lines = out.split("\n")
            for pattern in LOG_PATTERNS:
                for line in lines:
                    if pattern in line and not any(suppress in line for suppress in SUPPRESSED_PATTERNS):
                        alerts.append(f"[{node_name}] WARNING: Pattern '{pattern}' in {log}")
        except Exception as e:
            alerts.append(f"[{node_name}] ERROR: Could not read log {log}: {e}")
    return alerts

def check_postgres_snapshot():
    try:
        result = subprocess.run(
            ["sudo", "-S", "bash", "-c", "/root/genesis-tools/miscellaneous/bash/dbv2.sh"],
            input=f"{SUDO_PASSWORD}\n",
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            mastodon_dm(f"🚨 Snapshot verification failed:\nstdout:\n{result.stdout.strip()}\nstderr:\n{result.stderr.strip()}")
    except Exception as e:
        mastodon_dm(f"🚨 Snapshot verification failed to run: {e}")

def main():
    critical_problems = []
    warning_problems = []
    node_status = {}

    for node in NODES:
        status = "Healthy"
        raid_info = "All pools healthy"

        for disk in node["disks"]:
            disk_res = check_remote_disk(node["host"], node["ssh_user"], disk, node["name"])
            if disk_res:
                if "CRITICAL" in disk_res:
                    critical_problems.append(disk_res)
                    status = "Critical"
                elif "WARNING" in disk_res and status != "Critical":
                    warning_problems.append(disk_res)
                    status = "Warning"

        for svc in node["services"]:
            svc_res = check_remote_service(node["host"], node["ssh_user"], svc, node["name"])
            if svc_res:
                if "CRITICAL" in svc_res:
                    critical_problems.append(svc_res)
                    status = "Critical"
                elif "WARNING" in svc_res and status != "Critical":
                    warning_problems.append(svc_res)
                    status = "Warning"

        if node.get("db"):
            rep_res = check_replication(node["host"], node["name"])
            if rep_res:
                if "CRITICAL" in rep_res:
                    critical_problems.append(rep_res)
                    status = "Critical"
                else:
                    warning_problems.append(rep_res)
                    if status != "Critical":
                        status = "Warning"

        if node.get("raid", False):
            raid_res = check_remote_raid_md0(node["host"], node["ssh_user"], node["name"])
            if raid_res:
                if "CRITICAL" in raid_res:
                    critical_problems.append(raid_res)
                    status = "Critical"
                else:
                    warning_problems.append(raid_res)
                    if status != "Critical":
                        status = "Warning"
                raid_info = raid_res

        logs = check_remote_logs(node["host"], node["ssh_user"], node["name"])
        for log_alert in logs:
            warning_problems.append(log_alert)
            if status != "Critical":
                status = "Warning"

        node_status[node["name"]] = (status, raid_info)

    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    if critical_problems:
        formatted = "\n".join(f"- {choose_emoji(p)} {p}" for p in critical_problems)
        msg = f"🚨 Genesis Radio Critical Healthcheck {now} 🚨\n⚡ {len(critical_problems)} critical issues found:\n{formatted}"
        print(msg)
        mastodon_dm(msg)

    if warning_problems:
        formatted = "\n".join(f"- {choose_emoji(p)} {p}" for p in warning_problems)
        msg = f"⚠️ Genesis Radio Warning Healthcheck {now} ⚠️\n⚡ {len(warning_problems)} warnings found:\n{formatted}"
        print(msg)
        mastodon_dm(msg)

    if not critical_problems and not warning_problems:
        msg = f"✅ Genesis Radio Healthcheck {now}: All systems normal."
        print(msg)
        mastodon_dm(msg)

    with open(HEALTHCHECK_HTML, "w") as f:
        f.write("<html><head><title>Genesis Radio Healthcheck</title><meta http-equiv='refresh' content='60'></head><body>")
        f.write(f"<h1>Genesis Radio System Health</h1>")
        f.write(f"<p>Last Checked: {now}</p>")
        f.write("<table border='1' cellpadding='5' style='border-collapse: collapse;'><tr><th>System</th><th>Status</th><th>ZFS Details</th></tr>")
        for node, (status, zfs_info) in node_status.items():
            color = 'green' if 'Healthy' in status else ('orange' if 'Warning' in status else 'red')
            f.write(f"<tr><td>{node}</td><td style='color:{color};'>{status}</td><td><pre style='white-space: pre-wrap; font-size: small;'>{zfs_info}</pre></td></tr>")
        f.write("</table></body></html>")

    check_postgres_snapshot()

if __name__ == "__main__":
    main()
