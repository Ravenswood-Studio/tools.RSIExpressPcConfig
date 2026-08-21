Write-Host "================================="
Write-Host "   Remote Development SSH Setup   "
Write-Host "================================="

# This script must be elevated because Windows features, services, and firewall rules are system-wide.
$isAdministrator = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdministrator) {
    throw "Run setup.bat or this script as Administrator."
}

# Older PowerShell/.NET defaults to TLS 1.0, which GitHub's API and CDN reject.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$installDir = "$env:ProgramFiles\OpenSSH"
$sshdService = Get-Service -Name sshd -ErrorAction SilentlyContinue

if ($sshdService) {
    Write-Host "OpenSSH Server is already installed."
} else {
    Write-Host "Installing OpenSSH Server from the Win32-OpenSSH GitHub releases..."

    $arch = if ([Environment]::Is64BitOperatingSystem) { "Win64" } else { "Win32" }
    $assetName = "OpenSSH-$arch.zip"

    Write-Host "Looking up the latest Win32-OpenSSH release ($assetName)..."
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/PowerShell/Win32-OpenSSH/releases/latest" -Headers @{ "User-Agent" = "RSIExpressPcConfig" }
    $asset = $release.assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1
    if (-not $asset) {
        throw "Could not find a '$assetName' asset in the latest Win32-OpenSSH release."
    }

    $tempDir = Join-Path $env:TEMP "Win32-OpenSSH-Setup"
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

    $zipPath = Join-Path $tempDir $assetName
    Write-Host "Downloading $($asset.browser_download_url)..."
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing

    Write-Host "Extracting archive..."
    $extractDir = Join-Path $tempDir "extracted"
    Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

    # The zip contains a single top-level folder (e.g. OpenSSH-Win64) with the binaries and install script.
    $extractedRoot = Get-ChildItem -Path $extractDir -Directory | Select-Object -First 1
    if (-not $extractedRoot) {
        throw "Unexpected archive layout: no folder found inside $extractDir."
    }

    if (Test-Path $installDir) {
        Remove-Item $installDir -Recurse -Force
    }
    Move-Item -Path $extractedRoot.FullName -Destination $installDir

    Write-Host "Running install-sshd.ps1..."
    Push-Location $installDir
    try {
        & "$installDir\install-sshd.ps1"
    } finally {
        Pop-Location
    }

    Write-Host "Cleaning up downloaded files..."
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

    $sshdService = Get-Service -Name sshd -ErrorAction SilentlyContinue
    if (-not $sshdService) {
        throw "install-sshd.ps1 ran but the sshd service is missing. Check the output above for errors."
    }
}

# Make ssh/sshd/scp available on PATH without requiring a new shell session.
if ($env:Path -notlike "*$installDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$([Environment]::GetEnvironmentVariable('Path', 'Machine'));$installDir", "Machine")
    $env:Path += ";$installDir"
}

# Start the service now and set it to start automatically on boot.
Set-Service -Name sshd -StartupType Automatic
if ($sshdService.Status -ne 'Running') {
    Start-Service -Name sshd -ErrorAction Stop
}

# Open the firewall for inbound SSH connections on port 22.
$ruleName = "OpenSSH-Server-In-TCP"
if (-not (Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue)) {
    Write-Host "Creating firewall rule for SSH (port 22)..."
    New-NetFirewallRule -Name $ruleName -DisplayName "OpenSSH Server (sshd)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
} else {
    Write-Host "Firewall rule for SSH already exists."
}

# Use PowerShell as the default shell for SSH sessions instead of cmd.exe.
$psPath = (Get-Command powershell.exe).Source
New-Item -Path "HKLM:\SOFTWARE\OpenSSH" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name "DefaultShell" -Value $psPath

$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch 'Loopback' -and $_.IPAddress -notlike '169.254.*' } | Select-Object -First 1 -ExpandProperty IPAddress)
$currentUser = $env:USERNAME
$hostName = $env:COMPUTERNAME

Write-Host ""
Write-Host "SSH is configured and running."
Write-Host "Connect using: ssh $currentUser@$ip"
Write-Host "Hostname: $hostName"
Write-Host ""
Read-Host "Press Enter to close this window and continue with the setup..."
