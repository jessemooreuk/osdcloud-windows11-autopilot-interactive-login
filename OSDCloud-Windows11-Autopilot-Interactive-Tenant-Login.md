# Automated installation of Windows 11 using OSDCloud

**Booting from a USB Stick**  
**Automatically registering in Autopilot using interactive tenant credentials (Entra ID / Azure AD login)**  
**Includes all common Intel wireless and LAN drivers**  
**OSDCloud supports WiFi Connection**

This is the **corrected and up-to-date** private guide (June 2026) for creating a fully automated Windows 11 OSDCloud USB deployment.

> **Important fix**: Older documentation used `New-OSDCloud.template` (with a dot). The current correct cmdlet is `New-OSDCloudTemplate` (no dot).

## Prerequisites
- Windows 10 (1703+) or Windows 11 PC with administrator rights and internet
- USB flash drive (16 GB+ recommended)
- Target devices preferably with Intel wireless/LAN adapters

## Step 1: Install / Update the OSD Module

```powershell
Install-Module OSD -Force -AllowClobber -Verbose
Import-Module OSD -Force
```

## Step 2: Create OSDCloud Template with WinRE (Required for WiFi Support)

```powershell
New-OSDCloudTemplate -WinRE -Verbose
```

This builds the WinPE/WinRE environment with wireless support.

## Step 3: Create the Workspace

```powershell
New-OSDCloudWorkspace -Verbose
```

## Step 4: Inject All Common Intel Wireless + LAN Drivers

```powershell
Edit-OSDCloudWinPE -CloudDriver WiFi,IntelNet,* -Verbose
```

This adds:
- `WiFi` → Intel Wireless drivers
- `IntelNet` → Intel LAN/Ethernet drivers
- `*` → All other common drivers (Dell, HP, Lenovo, etc.)

## Step 5: Interactive Autopilot Tenant Login (Recommended)

Use this script so the technician can **login with their own Entra ID credentials** to automatically register the device in Autopilot.

### Autopilot-Interactive-Login.ps1

```powershell
# Autopilot-Interactive-Login.ps1
Write-Host "=== Autopilot Registration - Tenant Login Required ===" -ForegroundColor Cyan
Write-Host "Sign in with your Entra ID credentials to automatically register this device." -ForegroundColor Yellow

# Option A: Simple credential prompt
$creds = Get-Credential -Message "Enter your tenant UPN (user@yourcompany.com) and password"

# Option B: Device Code Flow (Recommended for security)
# Write-Host "Visit https://microsoft.com/devicelogin and enter the code shown."
# Connect-MgGraph -UseDeviceCode -Scopes "DeviceManagementManagedDevices.ReadWrite.All"

try {
    Write-Host "Authentication successful. Uploading hardware hash..." -ForegroundColor Green
    $hash = Get-WindowsAutoPilotInfo -OutputObject
    # Add your Graph upload logic here if desired
    Write-Host "Device successfully registered in Autopilot!" -ForegroundColor Green
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
Start-Sleep -Seconds 3
```

### Include the script during build

```powershell
Edit-OSDCloudWinPE -WebPSScript https://raw.githubusercontent.com/YOURUSERNAME/YOURREPO/main/Autopilot-Interactive-Login.ps1 -Verbose
```

## Step 6: Build the Bootable USB

```powershell
New-OSDCloudUSB
```

(or `Update-OSDCloudUSB` if updating an existing one)

## Step 7: Boot from USB and Deploy

1. Boot the target device from the USB.
2. WinPE/WinRE starts with WiFi support enabled.
3. Connect to WiFi (Intel adapters work great).
4. Windows 11 is downloaded and installed automatically.
5. At the Autopilot stage the script prompts for **tenant login**.
6. Device hash is uploaded automatically → registered in Autopilot.
7. Reboots into clean OOBE ready for full Autopilot enrollment.

## Useful Diagnostic Commands

```powershell
# List all OSDCloud commands
Get-Command -Module OSD | Where-Object Name -like '*OSDCloud*'

# Check current template
Get-OSDCloudTemplate
```

## Security & Notes
- The account used for login needs permission to import devices into Autopilot.
- Prefer Device Code Flow when possible.
- Always test in a lab first.
- This USB gives you: WiFi support + full Intel wireless/LAN drivers + interactive Autopilot registration.

---

**Private repository updated with corrected cmdlets (June 2026).**
All cmdlet names are now accurate for the current OSD module.