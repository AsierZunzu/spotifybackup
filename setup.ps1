Import-Module Spotishell

# Parse ENV
$RedirectUri = ($env:REDIRECT_URI ?? 'http://127.0.0.1:8080') + '/spotishell'

Write-Host "===== spotifybackup SETUP ====="

$SpotifyClientId = $env:CLIENT_ID ?? (Read-Host -Prompt 'Please provide Spotify Client ID')
$SpotifyClientSecret = $env:CLIENT_SECRET ?? (Read-Host -Prompt 'Please provide Spotify Client Secret')

try {
    $spotApp = Get-SpotifyApplication
}
catch {}

if ($null -eq $spotApp) {
    New-SpotifyApplication -ClientId $SpotifyClientId -ClientSecret $SpotifyClientSecret -RedirectUri $RedirectUri
}
elseif ($spotApp.ClientId -ne $SpotifyClientId -or $spotApp.ClientSecret -ne $SpotifyClientSecret) {
    Set-SpotifyApplication -ClientId $SpotifyClientId -ClientSecret $SpotifyClientSecret -RedirectUri $RedirectUri
}
Write-Host 'Initialize Spotify Application'
Initialize-SpotifyApplication

Write-Host 'Now you can run spotifybackup container'