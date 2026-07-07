# RSI Express PC Config

This utility helps with new Windows PC setup using one entry point: `setup.bat`.

## Contents

- `setup.bat` - Main launcher for the setup workflow.
- `RSI_PC_CONFIG/config.ps1` - New PC configuration script.
- `RSI_PC_CONFIG/optimizer.bat` - User optimization script (runs at next login for selected user).
- `RSI_PC_CONFIG/TVHS.exe` - TeamViewer installer package.
- `Windows Microsoft Login Bypass.txt` - Windows 11 local setup bypass notes.
- `Teamviewer Setup Link.txt` - TeamViewer custom link.

## 1. Windows 11 Login Bypass (If Needed During OOBE)

Use these steps only if Windows setup requires internet/Microsoft login and you need to continue offline:

1. Continue Windows setup until the **Choose a country** screen.
2. Press **Shift + F10**.
3. Run:
   `OOBE\BYPASSNRO`
4. Wait for reboot back into setup.
5. Press **Shift + F10** again.
6. Run:
   `ipconfig /release`
7. Complete Windows install.

Optional network recovery after install:

1. Open Command Prompt.
2. Run:
   `ipconfig /release`
3. Run:
   `ipconfig /renew`

## 2. Initial Local Account Standard During Windows Setup

Create the local administrator account during OOBE using this standard:

1. Admin username format:
   `Admin-ElementName`
2. Element name should use CamelCase (example: `FiberOptics`).
3. Example admin username:
   `Admin-FiberOptics`
4. Initial admin password during Windows setup can be:
   `pass`

After you run this utility, it rotates account passwords to strong random values.

## 3. Download And Prepare

1. Download the latest release ZIP from GitHub.
2. Extract the ZIP completely.
3. Open the extracted folder.
4. Right-click `setup.bat` and select **Run as administrator**.

> Important: Do not run from inside the ZIP preview. Extract first.

## 4. Run The Utility (setup.bat)

When `setup.bat` runs, it prompts for these actions:

1. **Install TeamViewer**
   - If `RSI_PC_CONFIG/TVHS.exe` exists, installer launches as admin.
2. **Configure a new PC**
   - Launches `RSI_PC_CONFIG/config.ps1` as admin.
   - Prompts for an element name and enforces:
     - Admin standard: `Admin-ElementName`
     - User standard: `User-ElementName`
   - Generates strong random passwords for both accounts.
3. **Optimize a user account**
   - Lists local users.
   - Copies `RSI_PC_CONFIG/optimizer.bat` to the chosen user's Startup folder.
4. **Restart**
   - Prompts for immediate restart.

## 5. Manual Fallback (If You Need To Run Config Only)

1. Open PowerShell as Administrator.
2. Change directory to `RSI_PC_CONFIG`.
3. Run:
   `powershell -ExecutionPolicy Bypass -File .\config.ps1`

## 6. Troubleshooting

- Error: `RSI_PC_CONFIG was not found`
  - You are likely running `setup.bat` from the wrong location or without extracting the full ZIP.
- TeamViewer installer missing
  - Confirm `RSI_PC_CONFIG/TVHS.exe` exists.
- Script blocked by policy
  - Run `setup.bat` as Administrator from an extracted folder.
- Optimizer cannot find Startup folder
  - Ensure the selected local user profile exists on disk.

## Security Notes

- `config.ps1` configures auto-logon and stores credentials in Windows logon registry settings as part of setup.
- `config.ps1` also writes a local setup log in the same script folder.
- Treat devices and generated logs as sensitive operational data.
