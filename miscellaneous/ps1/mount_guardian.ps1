# Genesis Radio Rclone Mount Guardian - Windows PowerShell Edition
# Author: Doc

$logfile = "C:\genesis_rclone_mount.log"

$assets_remote = "genesisassets:genesisassets"
$library_remote = "genesislibrary:genesislibrary"

$assets_drive = "Q:\"
$library_drive = "R:\"

$asset_cache_L = "L:\assetcache"
$asset_cache_X = "X:\cache"

$rclone_opts = "--vfs-cache-mode writes --vfs-cache-max-size 3T --vfs-cache-max-age 48h --vfs-read-ahead 1G --buffer-size 1G --no-traverse --rc --rc-addr :5572"

# Mastodon settings
$mastodonInstance = "https://chatwithus.live"
$mastodonToken = ""
$mastodonUserID = ""

function Log {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content $logfile "$timestamp : $args"
}

function Send-Mastodon-DM {
    param (
        [string]$message
    )

    $headers = @{
        "Authorization" = "Bearer $mastodonToken"
    }

    $body = @{
        "status" = $message
        "visibility" = "direct"
        "in_reply_to_account_id" = $mastodonUserID
    }

    try {
        Invoke-RestMethod -Uri "$mastodonInstance/api/v1/statuses" -Headers $headers -Method Post -Body $body
        Log "? Mastodon DM sent: $message"
    }
    catch {
        Log "? Failed to send Mastodon DM: $_"
    }
}

function Ensure-Mount {
    param (
        [string]$DriveLetter,
        [string]$Remote
    )

    if (Test-Path $DriveLetter) {
        Log "$DriveLetter already mounted."
    }
    else {
        Log "$DriveLetter is NOT mounted. Attempting to mount $Remote."

        Start-Process rclone -ArgumentList @(
            "mount", "$Remote", "$DriveLetter",
            "--cache-dir=$asset_cache_L",
            "--cache-dir=$asset_cache_X",
            $rclone_opts
        ) -WindowStyle Hidden

        Start-Sleep -Seconds 5

        if (Test-Path $DriveLetter) {
            Log "? Successfully mounted $DriveLetter"
        }
        else {
            Log "? Failed to mount $DriveLetter"
            Send-Mastodon-DM "?? Genesis Radio Ops: Failed to mount $DriveLetter after recovery attempt!"
        }
    }
}

# === Main ===

Log "===== Genesis Radio Rclone Mount Guardian starting ====="

Ensure-Mount -DriveLetter $assets_drive -Remote $assets_remote
Ensure-Mount -DriveLetter $library_drive -Remote $library_remote

Log "===== Genesis Radio Rclone Mount Guardian finished ====="
