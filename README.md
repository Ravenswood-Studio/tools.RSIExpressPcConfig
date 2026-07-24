# RSI Express PC Config

This utility helps with new Windows PC setup using one entry point: `setup.bat`.

## Contents

- `setup.bat` - Main launcher for the setup workflow.
- `RSI_PC_CONFIG/config.ps1` - New PC configuration script.
- `RSI_PC_CONFIG/optimizer.bat` - User optimization script (runs at next login for selected user).
- `RSI_PC_CONFIG/TVHS.exe` - TeamViewer installer package.
- `Windows Microsoft Login Bypass.txt` - Windows 11 local setup bypass notes.
- `Teamviewer Setup Link.txt` - TeamViewer custom link.

## 1. Windows 11 Login Bypass And Initial Local Account Setup (If Needed During OOBE)

Use these steps only if Windows setup requires internet/Microsoft login and you need to continue offline:

1. Ensure no ethernet cable is plugged into the computer.
2. Continue Windows setup until the **Choose a country** screen.
3. Press **Shift + F10**.
4. Run:
   `OOBE\BYPASSNRO`
5. Wait for reboot back into setup.
6. Press **Shift + F10** again.
7. Run:
   `ipconfig /release`
8. Continue setup. When prompted to connect to Wi-Fi, select **I don't have internet** to skip.
9. When prompted for **Who is going to use this device**, enter the admin account using this standard:
   `Admin-ElementName`
10. Use CamelCase for element names (example: `FiberOptics`).
11. Initial admin password during Windows setup can be:
    `pass`
12. For security questions, use this standard:
    - Question 1 answer: `FullElementNameSQ1`
    - Question 2 answer: `FullElementNameSQ2`
    - Question 3 answer: `FullElementNameSQ3`
13. Add the security questions and answers to element documentation.
14. On privacy settings, turn everything off:
    - Location
    - Find my device
    - Diagnostic data
    - Inking & typing
    - Personalized offers
15. Skip device registration if prompted.

Optional network recovery after install:

1. Open Command Prompt.
2. Run:
   `ipconfig /release`
3. Run:
   `ipconfig /renew`


## 2. Download And Prepare

1. Download the latest release ZIP from GitHub.
2. Extract the ZIP completely.
3. Open the extracted folder.
4. Right-click `setup.bat` and select **Run as administrator**.

> Important: Do not run from inside the ZIP preview. Extract first.

## 3. Run The Utility (setup.bat)

When `setup.bat` runs, it prompts for these actions:

1. **Install TeamViewer**
   - If `RSI_PC_CONFIG/TVHS.exe` exists, installer launches as admin.
2. **Configure a new PC**
   - Launches `RSI_PC_CONFIG/config.ps1` as admin.
   - Prompts for an element name and enforces:
     - Admin standard: `Admin-ElementName`
     - User standard: `User-ElementName`
   - Generates strong random passwords for both accounts.
   - After completion, save the generated config log (`RSI_PC_CONFIG/setup_log.txt`) in the job documentation folder.
   - Passwords are rotated during setup. If you do not save the config log or record the new admin password, you can lose access to the admin account.
3. **Optimize a user account**
   - Lists local users.
   - Copies `RSI_PC_CONFIG/optimizer.bat` to the chosen user's Startup folder.
4. **Restart**
   - Prompts for immediate restart.

## 4. Manual Fallback (If You Need To Run Config Only)

1. Open PowerShell as Administrator.
2. Change directory to `RSI_PC_CONFIG`.
3. Run:
   `powershell -ExecutionPolicy Bypass -File .\config.ps1`

## 5. Troubleshooting

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
- Save `RSI_PC_CONFIG/setup_log.txt` in the job documentation folder for each deployment.
- The setup process rotates account passwords. Record the rotated admin password immediately to avoid lockout.
- Treat devices and generated logs as sensitive operational data.
