@echo off
set "Root=%~dp0"
set "ConfigDir=%Root%RSI_PC_CONFIG"
set "TeamViewerExe=%ConfigDir%\TeamViewer_Host_Setup_x64.exe"
set "ConfigScript=%ConfigDir%\config.ps1"
set "OptimizerMachineScript=%ConfigDir%\optimizer_machine.bat"
set "OptimizerUserScript=%ConfigDir%\optimizer_user.bat"
set "SshScript=%ConfigDir%\setup_ssh.ps1"
set "DidConfig=0"

if not exist "%ConfigDir%" (
    echo ERROR: "%ConfigDir%" was not found.
    echo Make sure you extracted the full GitHub release ZIP before running setup.bat.
    pause
    exit /b 1
)

echo Using local configuration files from:
echo %ConfigDir%
echo.

set /p installTV="Would you like to install Teamviewer? (Y/N): "
if /I "%installTV%"=="Y" (
    if exist "%TeamViewerExe%" (
        echo Running Teamviewer installer as administrator...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%TeamViewerExe%' -Verb RunAs"
        echo Please follow the installer instructions to install Teamviewer.
        pause
    ) else (
        echo Teamviewer installer was not found at:
        echo %TeamViewerExe%
        echo Skipping Teamviewer installation.
    )
) else (
    echo Skipping Teamviewer installation.
)

set /p setupSsh="Would you like to configure the machine for remote development (setup SSH)? (Y/N): "
if /I "%setupSsh%"=="Y" (
    if exist "%SshScript%" (
        echo Running SSH configuration script as administrator...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'PowerShell' -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%SshScript%""' -Verb RunAs -Wait"
        echo SSH configuration complete.
    ) else (
        echo setup_ssh.ps1 was not found at:
        echo %SshScript%
        echo Skipping SSH configuration.
    )
) else (
    echo Skipping SSH configuration.
)

set /p configPC="Would you like to configure a new PC? (Y/N): "
if /I "%configPC%"=="Y" (
    if exist "%ConfigScript%" (
        set "DidConfig=1"
        echo Running PC configuration script as administrator...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'PowerShell' -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%ConfigScript%""' -Verb RunAs"
        echo Please follow the instructions in the PowerShell window to complete PC configuration.
        pause
    ) else (
        echo config.ps1 was not found at:
        echo %ConfigScript%
        echo Skipping PC configuration.
    )
) else (
    echo Skipping PC configuration.
)

set /p optimizeMachine="Would you like to optimize this machine? (Y/N): "
if /I "%optimizeMachine%"=="Y" (
    if not exist "%OptimizerMachineScript%" (
        echo optimizer_machine.bat was not found at:
        echo %OptimizerMachineScript%
        echo Skipping machine optimization.
        goto :AFTER_OPTIMIZE
    )
    if not exist "%OptimizerUserScript%" (
        echo optimizer_user.bat was not found at:
        echo %OptimizerUserScript%
        echo Skipping machine optimization.
        goto :AFTER_OPTIMIZE
    )

    echo Running optimizer_machine.bat as administrator...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'cmd' -ArgumentList '/c \"%OptimizerMachineScript%\"' -Verb RunAs -Wait"
    echo Machine optimization complete.
) else (
    echo Skipping machine optimization.
)

:AFTER_OPTIMIZE
echo Setup tasks are complete.
set /p exitNow="Would you like to exit now? (Y/N): "
if /I "%exitNow%"=="Y" (
    if "%DidConfig%"=="1" (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; $configDir = '%ConfigDir%'; $logCandidate = Get-ChildItem -Path $configDir -Filter '*_setup_log.txt' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if ($logCandidate) { $logPath = $logCandidate.FullName } else { $logPath = Join-Path $configDir 'setup_log.txt' }; $adminPassword = ''; if (Test-Path $logPath) { $raw = Get-Content -Path $logPath -Raw -ErrorAction SilentlyContinue; if ($raw -match 'Admin Account Login[\s\S]*?Password:\s*(.+)') { $adminPassword = $matches[1].Trim() } }; $nl = [Environment]::NewLine; if ([string]::IsNullOrWhiteSpace($adminPassword)) { $msg = 'WARNING: The admin account password was rotated during setup.' + $nl + $nl + 'Before exit, save the generated config log to the job documentation folder and record the new admin password.' } else { $msg = 'WARNING: The admin account password was rotated during setup.' + $nl + $nl + 'Admin password: ' + $adminPassword + $nl + $nl + 'Before exit, save the generated config log to the job documentation folder and record this password.' }; [System.Windows.Forms.MessageBox]::Show($msg, 'Exit Warning', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null"
    )
    echo Exiting setup...
    exit /b 0
) else (
    echo Setup will remain open. Close this window when ready.
    pause
)
