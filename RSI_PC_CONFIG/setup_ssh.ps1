Write-Host "================================="
Write-Host "   Remote Development SSH Setup   "
Write-Host "================================="

# Install the OpenSSH Server optional feature if it is not already present.
$sshCapability = Get-WindowsCapability -Online | Where-Object { $_.Name -like 'OpenSSH.Server*' }
if ($sshCapability.State -ne 'Installed') {
    Write-Host "Installing OpenSSH Server..."
    Add-WindowsCapability -Online -Name $sshCapability.Name | Out-Null
} else {
    Write-Host "OpenSSH Server is already installed."
}

# Start the service now and set it to start automatically on boot.
Set-Service -Name sshd -StartupType Automatic
Start-Service -Name sshd

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
