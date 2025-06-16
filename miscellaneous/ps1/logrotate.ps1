# Rotate Genesis Mount Guardian Logs
# Author: You

$logfile = "C:\genesis_rclone_mount.log"
$archiveFolder = "C:\log_archive"
$maxSizeMB = 5

# Create archive folder if missing
if (!(Test-Path $archiveFolder)) {
    New-Item -ItemType Directory -Path $archiveFolder
}

# Check if logfile exists and size
if (Test-Path $logfile) {
    $fileSizeMB = (Get-Item $logfile).Length / 1MB

    if ($fileSizeMB -ge $maxSizeMB) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $archivePath = Join-Path $archiveFolder "genesis_rclone_mount_$timestamp.log"
        Move-Item $logfile $archivePath
        Write-Output "? Rotated log to $archivePath"
    } else {
        Write-Output "?? Log size is fine ($([math]::Round($fileSizeMB,2)) MB). No rotation needed."
    }
} else {
    Write-Output "?? Log file not found. Nothing to rotate."
}
