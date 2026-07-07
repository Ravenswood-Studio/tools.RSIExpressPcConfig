Write-Host "================================="
Write-Host "|    _____     _____   _____    |"
Write-Host "|   |  __ \   / ____| |_   _|   |"
Write-Host "|   | |__) | | (___     | |     |"
Write-Host "|   |  _  /   \___ \    | |     |"
Write-Host "|   | | \ \   ____) |  _| |_    |"
Write-Host "|   |_|  \_\ |_____/  |_____|   |"
Write-Host "|      Express Config Tool      |"
Write-Host "================================="

# Define log file path (same directory as the script)
$LogFile = "$PSScriptRoot\setup_log.txt"

# Start logging
Add-Content -Path $LogFile -Value "Auto Generated File By RSI.EXPRESS_CONFIG"

Add-Content -Path $LogFile -Value "============================="
Add-Content -Path $LogFile -Value "Computer Configuration"
Add-Content -Path $LogFile -Value "============================="

# Get System Information
$SystemInfo = Get-WmiObject -Class Win32_ComputerSystem
$Processor = (Get-WmiObject -Class Win32_Processor).Name
$RAM = [math]::round($SystemInfo.TotalPhysicalMemory / 1GB, 2)
$Disk = (Get-WmiObject -Class Win32_DiskDrive).Model
$OS = (Get-WmiObject -Class Win32_OperatingSystem).Caption
$ServiceTag = (Get-WmiObject -Class Win32_BIOS).SerialNumber
$ExpressServiceCode = (Get-WmiObject -Class Win32_ComputerSystemProduct).UUID
$CurrentMachineName = $env:COMPUTERNAME

# Log system info
Add-Content -Path $LogFile -Value "Computer: $($SystemInfo.Manufacturer) $($SystemInfo.Model)"
Add-Content -Path $LogFile -Value "Processor: $Processor"
Add-Content -Path $LogFile -Value "RAM: $RAM GB DDR4"
Add-Content -Path $LogFile -Value "Disk: $Disk"
Add-Content -Path $LogFile -Value "Operating System: $OS"
Add-Content -Path $LogFile -Value "Machine Name: $CurrentMachineName"
Add-Content -Path $LogFile -Value "Service Tag (ST): $ServiceTag"
Add-Content -Path $LogFile -Value "Express Service Code: $ExpressServiceCode"
Add-Content -Path $LogFile -Value ""

Add-Content -Path $LogFile -Value "============================="
Add-Content -Path $LogFile -Value "Hostname"
Add-Content -Path $LogFile -Value "============================="

# Build a standardized ElementName segment using CamelCase words.
function Convert-ToElementName {
    param([string]$RawValue)

    $parts = @($RawValue -split '[^A-Za-z0-9]+' | Where-Object { $_ -and $_.Length -gt 0 })
    if ($parts.Count -eq 0) {
        return ""
    }

    return (($parts | ForEach-Object {
        $first = $_.Substring(0, 1).ToUpper()
        if ($_.Length -gt 1) {
            $rest = $_.Substring(1).ToLower()
            "$first$rest"
        } else {
            $first
        }
    }) -join '')
}

# Generate strong random passwords with a mix of character classes.
function New-StrongPassword {
    param([int]$Length = 20)

    $lower = 'abcdefghijkmnopqrstuvwxyz'.ToCharArray()
    $upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ'.ToCharArray()
    $digits = '23456789'.ToCharArray()
    $special = '!@$%&*?-_#'.ToCharArray()
    $all = $lower + $upper + $digits + $special

    $chars = @(
        ($lower | Get-Random),
        ($upper | Get-Random),
        ($digits | Get-Random),
        ($special | Get-Random)
    )

    for ($i = $chars.Count; $i -lt $Length; $i++) {
        $chars += ($all | Get-Random)
    }

    -join ($chars | Sort-Object { Get-Random })
}

# Prompt user for new machine name
$MachineName = Read-Host "Enter new machine name"
Rename-Computer -NewName $MachineName -Force
Write-Host "Machine has been renamed to '$MachineName'."
Add-Content -Path $LogFile -Value "Host Name: $MachineName"

# Define element/account naming standards
do {
    $RawElementName = Read-Host "Enter element name for account standard (example: FiberOptics)"
    $ElementName = Convert-ToElementName -RawValue $RawElementName
    if ([string]::IsNullOrWhiteSpace($ElementName)) {
        Write-Host "Invalid element name. Use letters/numbers only."
    }
} while ([string]::IsNullOrWhiteSpace($ElementName))

$ExpectedAdminUsername = "Admin-$ElementName"
$Username = "User-$ElementName"

# Get the currently logged-in admin account
$AdminUsername = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]

if ($AdminUsername -ne $ExpectedAdminUsername) {
    Write-Host "WARNING: Current admin account is '$AdminUsername'. Expected naming standard is '$ExpectedAdminUsername'."
}

# Generate and set a strong random admin password.
$AdminPasswordText = New-StrongPassword -Length 12
$AdminPassword = ConvertTo-SecureString -String $AdminPasswordText -AsPlainText -Force

# Set the new password for the admin account
Set-LocalUser -Name $AdminUsername -Password $AdminPassword
Write-Host "Random password for admin account '$AdminUsername' has been set."
Write-Host "Admin Password: $AdminPasswordText"

# Log admin account details (use admin's current name and password for documentation)
Add-Content -Path $LogFile -Value ""
Add-Content -Path $LogFile -Value "============================="
Add-Content -Path $LogFile -Value "Admin Account Login"
Add-Content -Path $LogFile -Value "============================="
Add-Content -Path $LogFile -Value "Username: $AdminUsername"
Add-Content -Path $LogFile -Value "Password: $AdminPasswordText"

# Generate and apply a strong random password for the standard user account.
$PasswordText = New-StrongPassword -Length 8
$Password = ConvertTo-SecureString -String $PasswordText -AsPlainText -Force

# Create the user account as a standard user
if (Get-LocalUser -Name $Username -ErrorAction SilentlyContinue) {
    Set-LocalUser -Name $Username -Password $Password
    Write-Host "User account '$Username' already existed. Password has been updated."
} else {
    New-LocalUser -Name $Username -Password $Password -FullName $Username -Description "Standard User Account"
    Write-Host "User account '$Username' has been created as a standard user."
}
Write-Host "User Password: $PasswordText"

# Force profile folder creation for the new user
try {
    $secPassword = $Password
    $cred = New-Object System.Management.Automation.PSCredential($Username, $secPassword)
    Start-Process -FilePath "cmd.exe" -Credential $cred -ArgumentList "/c exit" -WindowStyle Hidden -ErrorAction Stop
    Write-Host "Profile folder for '$Username' has been generated."
} catch {
    Write-Host "Could not force profile folder creation for '$Username'. User must log in at least once."
}

# Log user account details (use admin's current name and password for documentation)
Add-Content -Path $LogFile -Value ""
Add-Content -Path $LogFile -Value "============================="
Add-Content -Path $LogFile -Value "User Account Login"
Add-Content -Path $LogFile -Value "============================="
Add-Content -Path $LogFile -Value "Username: $Username"
Add-Content -Path $LogFile -Value "Password: $PasswordText"

# Run bcdedit commands in CMD as admin
$cmdArgs = "/c bcdedit /set {default} bootstatuspolicy ignoreshutdownfailures && bcdedit /set {default} recoveryenabled No"
Start-Process cmd.exe -ArgumentList $cmdArgs -Verb RunAs -Wait
Write-Host "Boot status policy set to ignore shutdown failures."

# Log system changes
Add-Content -Path $LogFile -Value ""
Add-Content -Path $LogFile -Value "============================="
Add-Content -Path $LogFile -Value "System Changes"
Add-Content -Path $LogFile -Value "============================="
Add-Content -Path $LogFile -Value "Ignore Shutdown Failures: bcdedit /set {default} bootstatuspolicy ignoreshutdownfailures"
Add-Content -Path $LogFile -Value "Disable Recovery: bcdedit /set {default} recoveryenabled No"

# Apply registry edits
$RegPaths = @(
    "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\LockDown",
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU",
    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
)

# Disable Edge Swipe
Set-ItemProperty -Path $RegPaths[0] -Name "AllowEdgeSwipe" -Value 0 -Type DWord
Write-Host "Edge Swipe has been disabled."
Add-Content -Path $LogFile -Value ""
Add-Content -Path $LogFile -Value "Disable Edge Swipe:"
Add-Content -Path $LogFile -Value "[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\default\LockDown\AllowEdgeSwipe]"
Add-Content -Path $LogFile -Value """value""=dword:00000000"

# Turn Off Windows 11 Update
If (!(Test-Path $RegPaths[1])) { New-Item -Path $RegPaths[1] -Force | Out-Null }
Set-ItemProperty -Path $RegPaths[1] -Name "NoAutoUpdate" -Value 1 -Type DWord
Write-Host "Windows Update has been turned off."
Add-Content -Path $LogFile -Value ""
Add-Content -Path $LogFile -Value "Turn Off Windows 11 Update"
Add-Content -Path $LogFile -Value "[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU]"
Add-Content -Path $LogFile -Value """NoAutoUpdate""=dword:00000001"

# Enable Auto Logon Store password in registry (SR)
Set-ItemProperty -Path $RegPaths[2] -Name "AutoAdminLogon" -Value "1" -Type String
Set-ItemProperty -Path $RegPaths[2] -Name "DefaultUserName" -Value $Username -Type String
Set-ItemProperty -Path $RegPaths[2] -Name "DefaultPassword" -Value $PasswordText -Type String

Write-Host "Auto logon has been configured for user '$Username'."

Add-Content -Path $LogFile -Value ""
Add-Content -Path $LogFile -Value "Enable Auto Logon"
Add-Content -Path $LogFile -Value "[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsNT\CurrentVersion\Winlogon]"
Add-Content -Path $LogFile -Value """AutoAdminLogon""=string:1"
Add-Content -Path $LogFile -Value """DefaultUserName""=string:$Username"
Add-Content -Path $LogFile -Value """DefaultPassword""=string:$PasswordText"

# ----------------------
# Disable Sleep & Screensaver
# ----------------------
powercfg /change monitor-timeout-ac 0
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
Write-Host "Sleep and screensaver have been disabled."

Add-Content -Path $LogFile -Value ""
Add-Content -Path $LogFile -Value "Disable Sleep & Screensaver:"
Add-Content -Path $LogFile -Value "powercfg /change monitor-timeout-ac 0"
Add-Content -Path $LogFile -Value "powercfg /change standby-timeout-ac 0"
Add-Content -Path $LogFile -Value "powercfg /change hibernate-timeout-ac 0"

Add-Content -Path $LogFile -Value ""
Add-Content -Path $LogFile -Value "Deactivate Gestures (Must be plugged into a Touch enabled device)"
Add-Content -Path $LogFile -Value "1. Start > Settings > Bluetooth & Devices > Touch > Three- and four-finger touch gestures"
Add-Content -Path $LogFile -Value "2. Set to off"
Add-Content -Path $LogFile -Value ""
Add-Content -Path $LogFile -Value "Set BIOS to Boot on Power Connection"
Add-Content -Path $LogFile -Value "1. In the system BIOS Under Power:"
Add-Content -Path $LogFile -Value "2. AC Behavior >AC Recovery > Power On"
Add-Content -Path $LogFile -Value ""

# Output log file path to user
Write-Host "Log file saved to: $LogFile"

Add-Content -Path $LogFile -Value "Setup complete. The system may require a restart."