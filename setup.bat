@echo off
set "Root=%~dp0"
set "ConfigDir=%Root%RSI_PC_CONFIG"
set "TeamViewerExe=%ConfigDir%\TVHS.exe"
set "ConfigScript=%ConfigDir%\config.ps1"
set "OptimizerScript=%ConfigDir%\optimizer.bat"
set "ConfigLog=%ConfigDir%\setup_log.txt"
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

set /p optimizeUser="Would you like to optimize a user account? (Y/N): "
if /I "%optimizeUser%"=="Y" (
    if not exist "%OptimizerScript%" (
        echo optimizer.bat was not found at:
        echo %OptimizerScript%
        echo Skipping user account optimization.
        goto :AFTER_OPTIMIZE
    )

    setlocal enabledelayedexpansion
    echo Listing user accounts...
    set /a idx=0
    for /f "usebackq delims=" %%u in (`powershell -NoProfile -Command "Get-LocalUser ^| Select-Object -ExpandProperty Name"`) do (
        set /a idx+=1
        set "user[!idx!]=%%u"
        echo !idx!. %%u
    )

    if !idx! EQU 0 (
        endlocal
        echo ERROR: No local users were found. Skipping user account optimization.
        goto :AFTER_OPTIMIZE
    )

    set /p userChoice="Enter the number of the user to optimize: "

    set "chosenUser=!user[%userChoice%]!"
    if not defined chosenUser (
        endlocal
        echo ERROR: Invalid selection. Skipping user account optimization.
        goto :AFTER_OPTIMIZE
    )
    for %%N in ("!chosenUser!") do endlocal & set "chosenUser=%%~N"

    rem Copy optimizer.bat to the selected user's Startup folder for one-time execution
    set "startupFolder=C:\Users\%chosenUser%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"

    if exist "%startupFolder%" (
        echo Startup folder exists for %chosenUser%.
    ) else (
        echo Startup folder for %chosenUser% not found. Creating it now...
        mkdir "%startupFolder%" 2>nul
        if errorlevel 1 (
            echo ERROR: Could not create "%startupFolder%". Make sure the profile path is correct and you have permissions.
            goto :AFTER_OPTIMIZE
        ) else (
            echo Created "%startupFolder%".
        )
    )

    copy "%OptimizerScript%" "%startupFolder%\" /Y
    if errorlevel 1 (
        echo ERROR: Failed to copy optimizer.bat into "%startupFolder%".
    ) else (
        echo Optimizer has been placed in the Startup folder for %chosenUser%. It will run at next login.
    )
) else (
    echo Skipping user account optimization.
)

:AFTER_OPTIMIZE
echo A system restart is required to complete setup.
set /p restartNow="Would you like to restart now? (Y/N): "
if /I "%restartNow%"=="Y" (
    if "%DidConfig%"=="1" (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; $logPath = '%ConfigLog%'; $adminPassword = ''; if (Test-Path $logPath) { $raw = Get-Content -Path $logPath -Raw -ErrorAction SilentlyContinue; if ($raw -match 'Admin Account Login[\s\S]*?Password:\s*(.+)') { $adminPassword = $matches[1].Trim() } }; if ([string]::IsNullOrWhiteSpace($adminPassword)) { $msg = 'WARNING: The admin account password was rotated during setup.`r`n`r`nBefore restart, save setup_log.txt to the job documentation folder and record the new admin password.' } else { $msg = 'WARNING: The admin account password was rotated during setup.`r`n`r`nAdmin password: ' + $adminPassword + '`r`n`r`nBefore restart, save setup_log.txt to the job documentation folder and record this password.' }; [System.Windows.Forms.MessageBox]::Show($msg, 'Restart Warning', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null"
    )
    echo Restarting system...
    shutdown /r /t 0
) else (
    echo Please restart your computer manually to complete setup.
    pause
)
