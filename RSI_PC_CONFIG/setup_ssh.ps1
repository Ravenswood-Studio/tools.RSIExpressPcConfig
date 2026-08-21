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

# Install the OpenSSH Server optional feature if it is not already present.
$sshCapabilityName = 'OpenSSH.Server~~~~0.0.1.0'
$sshCapability = Get-WindowsCapability -Online -Name $sshCapabilityName -ErrorAction Stop
if ($sshCapability.State -ne 'Installed') {
    Write-Host "Installing OpenSSH Server..."
    $installResult = Add-WindowsCapability -Online -Name $sshCapabilityName -ErrorAction Stop
    if ($installResult.RestartNeeded) {
        Write-Warning "Windows requires a restart before OpenSSH can start. Restart the PC and run this setup again."
        exit 1
    }
} else {
    Write-Host "OpenSSH Server is already installed."
}

# Confirm installation actually registered the sshd service before trying to start it.
$sshdService = Get-Service -Name sshd -ErrorAction SilentlyContinue
if (-not $sshdService) {
    throw "OpenSSH Server was not installed, so the sshd service is missing. Check Windows Update or specify a local feature source."
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
