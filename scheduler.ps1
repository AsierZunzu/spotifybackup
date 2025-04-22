Import-Module Spotishell

$VersionNumber = '1.0.1'

function Write-Log {
    param (
        $Message
    )
    Write-Host "$(Get-Date -UFormat '%F-%T') : $Message"
}


function Execute-Backup {
    param (
        $BackupPrefix,
        $BackupStorePath
    )
    Write-Log 'Backing up'
    $backupFileName = "$BackupPrefix-$(Get-Date -AsUTC -UFormat '%F-%H-%M').json"
    Backup-Library -Path "$BackupStorePath/$backupFileName"
    Write-Log "Library backed up to file '$backupFileName'"
}

function Clean-Backups {
    param (
        $BackupRetention,
        $BackupStorePath
    )
    Write-Log 'Cleaning up old backups'
    $backupFiles = Get-ChildItem -Path $env:BACKUP_STORE_PATH -Filter "$BackupPrefix-*" | Sort-Object -Property Name
    if (-not($backupFiles.Count -gt $BackupRetention)) {
        Write-Log 'No backup file over retention to remove'
        return
    }
    foreach ($file in $backupFiles[0..$($backupFiles.Count - $BackupRetention - 1)]) {
        Remove-Item $file
        Write-Log "$($file.Name) removed"
    }
}

Write-Log "===== spotifybackup v$VersionNumber ====="

# Parse ENV
$BackupHour = $env:BACKUP_HOUR ?? 2
$BackupRetention = $env:BACKUP_RETENTION ?? 30
$BackupPrefix = $env:BACKUP_PREFIX ?? 'SpotifyBackup'


# Verify Spotify Application
try {
    Get-SpotifyApplication | Out-Null
}
catch {
    Write-Log 'Spotify Application is not set. Please run this configuration command line first : '
    Write-Log '    docker run -it --rm -v spotifybackup:/data --entrypoint pwsh spotifybackup:latest setup.ps1'
    Write-Log 'Exiting...'
    Exit
}

Initialize-SpotifyApplication

$nextBackupTime = (Get-Date).Date.AddHours($BackupHour)
if ($nextBackupTime -le (Get-Date)) { $nextBackupTime = $nextBackupTime.AddDays(1) }
Write-Log ('Now waiting for the next backup time => ' + ($nextBackupTime | Get-Date -UFormat '%F %T'))

$lastBackupTime = Get-Date

while ($true) {

    $now = Get-Date
    $todayBackupTime = (Get-Date).Date.AddHours($BackupHour)

    # if today backup time is between $lastBackupTime and $now, then backup

    if ($lastBackupTime -lt $todayBackupTime -and $todayBackupTime -le $now) {

        Execute-Backup $BackupPrefix $env:BACKUP_STORE_PATH
        Clean-Backups $BackupRetention $env:BACKUP_STORE_PATH
        Write-Log 'Backup process finished'

        # Update last backup time
        $lastBackupTime = $todayBackupTime
    }

    # Wait 1 second
    Start-Sleep -Seconds 1
}