# RSI Express PC Config

This utility helps with new Windows PC setup using one entry point: `setup.bat`.

## Contents

- `setup.bat` - Main launcher for the setup workflow.
- `RSI_PC_CONFIG/config.ps1` - New PC configuration script.
- `RSI_PC_CONFIG/optimizer_machine.bat` - Machine-wide optimization script (requires admin credentials; runs at next login for selected user).
- `RSI_PC_CONFIG/optimizer_user.bat` - Per-user optimization script (no admin required; runs at next login for selected user).
- `RSI_PC_CONFIG/setup_ssh.ps1` - Configures the machine for remote development (OpenSSH Server).
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

1. Download the latest release ZIP from GitHub:
   https://github.com/Ravenswood-Studio/tools.RSIExpressPcConfig
2. Extract the ZIP completely.
3. Open the extracted folder.
4. Right-click `setup.bat` and select **Run as administrator**.

> Important: Do not run from inside the ZIP preview. Extract first.

## 3. Run The Utility (setup.bat)

When `setup.bat` runs, it prompts for these actions:

1. **Install TeamViewer**
   - If `RSI_PC_CONFIG/TVHS.exe` exists, installer launches as admin.
2. **Configure remote development (setup SSH)**
   - Launches `RSI_PC_CONFIG/setup_ssh.ps1` as admin.
   - Installs and starts the OpenSSH Server feature, sets it to start automatically, and opens the firewall for port 22.
   - Sets PowerShell as the default shell for SSH sessions.
   - Prints the connection command (`ssh user@ip`) for remote access.
3. **Configure a new PC**
   - Launches `RSI_PC_CONFIG/config.ps1` as admin.
   - Prompts for an element name and enforces:
     - Admin standard: `Admin-ElementName`
     - User standard: `User-ElementName`
   - Generates strong random passwords for both accounts.
   - After completion, save the generated config log (`RSI_PC_CONFIG/ElementName_setup_log.txt`) in the job documentation folder.
   - Passwords are rotated during setup. If you do not save the config log or record the new admin password, you can lose access to the admin account.
4. **Optimize this machine**
   - Runs `RSI_PC_CONFIG/optimizer_machine.bat` as admin in a new window and waits for it to finish. It applies machine-wide tweaks (HKLM policies, services, scheduled tasks, system-wide app removal).
   - After it completes, copies `RSI_PC_CONFIG/optimizer_user.bat` into the Default profile's Startup folder (creating the folder if needed). Since new Windows profiles are cloned from the Default profile, it runs with no prompt at first login for every user created afterward, applying tweaks scoped to that user's own profile (HKCU, OneDrive user data).
5. **Exit**
   - Prompts to exit setup.
   - If PC configuration was run, shows a warning popup with rotated admin password details before closing.

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
  - Ensure `C:\Users\Default` exists and you have permissions to create folders under it.

## Security Notes

- `config.ps1` configures auto-logon and stores credentials in Windows logon registry settings as part of setup.
- `config.ps1` also writes a local setup log in the same script folder.
- Save `RSI_PC_CONFIG/ElementName_setup_log.txt` in the job documentation folder for each deployment.
- The setup process rotates account passwords. Record the rotated admin password immediately to avoid lockout.
- Treat devices and generated logs as sensitive operational data.
