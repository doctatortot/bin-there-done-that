📜 Genesis Radio Mission Control Runbook (v1)
🛡️ Genesis Radio Mission Control: Ops Runbook

    Purpose:
    Quickly diagnose and fix common Genesis Radio infrastructure issues without guesswork, even under pressure.

🚨 If a Mount is Lost (Q:\ or R:)

Symptoms:

    Station playback errors

    Skipping or dead air after a Station ID

    Log shows: Audio Engine Timeout on Q:\ or R:\ paths

Immediate Actions:

    Check if drives Q:\ and R:\ are visible in Windows Explorer.

    Open C:\genesis_rclone_mount.log and check last 10 lines.

    Run Mount Guardian manually:

    powershell.exe -ExecutionPolicy Bypass -File "C:\scripts\mount_guardian.ps1"

    Wait 15 seconds.

    Verify that Q:\ and R:\ reappear.

    If re-mounted, check logs for successful ✅ mount entry.

If Mount Guardian fails to remount:

    Check if rclone.exe is missing or updated incorrectly.

    Check disk space on L:\ and X:\ cache drives.

    Manually run rclone mounts with correct flags (see below).

🛠️ Manual Rclone Mount Commands (Emergency)

rclone mount genesisassets:genesisassets Q:\ --vfs-cache-mode writes --vfs-cache-max-size 3T --vfs-cache-max-age 48h --vfs-read-ahead 1G --buffer-size 1G --cache-dir L:\assetcache --cache-dir X:\cache --no-traverse --rc --rc-addr :5572

rclone mount genesislibrary:genesislibrary R:\ --vfs-cache-mode writes --vfs-cache-max-size 3T --vfs-cache-max-age 48h --vfs-read-ahead 1G --buffer-size 1G --cache-dir L:\assetcache --cache-dir X:\cache --no-traverse --rc --rc-addr :5572

✅ Always mount assets (Q:) first, then library (R:).
📬 If Mastodon DMs a Mount Failure Alert

Message example:

    🚨 Genesis Radio Ops: Failed to mount Q:\ after recovery attempt!

Actions:

    Immediately check C:\genesis_rclone_mount.log

    Verify if the mount succeeded after retry

    If not: manually run Mount Guardian

    Escalate if disk space or critical cache drive failure suspected

📊 If Dashboard Data Looks Broken

Symptoms:

    Health dashboard empty

    No refresh

    Tables missing

Actions:

    Check that healthcheck HTML generator is still scheduled.

    SSH into Krang:

systemctl status healthcheck.timer

Restart healthcheck if necessary:

    systemctl restart healthcheck.timer

    Check /var/www/html/healthcheck.html timestamp.

🧹 Log Rotation and Space

    Logfile is rotated automatically weekly if over 5MB.

    If needed manually:

    powershell.exe -ExecutionPolicy Bypass -File "C:\scripts\rotate_mount_logs.ps1"

🐢 Critical Reminders (Go Slow to Go Fast)

    Breathe. Double-check before restarting services.

    Don't panic-restart Windows unless all mount attempts fail.

    Document what you changed. Always.

🛡️ Mission: Keep Genesis Radio running, clean, and stable.

Scripters are smarter than panickers.
Calm is contagious.
