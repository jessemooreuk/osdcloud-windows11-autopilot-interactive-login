# Automated installation of Windows 11 using OSDCloud

**Booting from a USB Stick**  
**Automatically registering in Autopilot (Tenant-Agnostic + Audit Mode)**  
**Includes all common Intel wireless and LAN drivers**  
**OSDCloud supports WiFi Connection**

**Fully Automated Version (Local Scripts + Auto Execution)**

## Recommended Build Process

Use the automated build script or follow the steps below.

### 1. Download Scripts

Place these files in `C:\OSDCloudScripts`:
- `Collect-AutopilotHash-WinPE.ps1`
- `AuditMode-AutopilotUpload.ps1`

### 2. Run Build (Recommended)

```powershell
. C:\OSDCloudScripts\Build-OSDCloudUSB.ps1
```

Or do it manually:

```powershell
Install-Module OSD -Force -AllowClobber
Import-Module OSD -Force

New-OSDCloudTemplate -WinRE -Verbose
New-OSDCloudWorkspace -Verbose

Edit-OSDCloudWinPE -CloudDriver WiFi,IntelNet,* -Verbose

# Copy scripts locally
$scriptsPath = "$env:ProgramData\OSDCloud\Workspace\Scripts"
New-Item -Path $scriptsPath -ItemType Directory -Force
Copy-Item "C:\OSDCloudScripts\Collect-AutopilotHash-WinPE.ps1" -Destination $scriptsPath -Force
Copy-Item "C:\OSDCloudScripts\AuditMode-AutopilotUpload.ps1" -Destination $scriptsPath -Force

# Make hash collection run automatically in WinPE
$startnetFile = Get-ChildItem -Path "$env:ProgramData\OSDCloud\Template" -Recurse -Filter "Startnet.cmd" | Select-Object -First 1 -ExpandProperty FullName
Add-Content -Path $startnetFile -Value "powershell -NoLogo -File X:\Scripts\Collect-AutopilotHash-WinPE.ps1"

# Unattend for automatic Audit Mode
$unattend = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <Reseal>
        <Mode>Audit</Mode>
      </Reseal>
      <FirstLogonCommands>
        <SynchronousCommand wcm:action="add">
          <Order>1</Order>
          <CommandLine>powershell -NoLogo -File "C:\Scripts\AuditMode-AutopilotUpload.ps1"</CommandLine>
        </SynchronousCommand>
      </FirstLogonCommands>
    </component>
  </settings>
</unattend>
'@ 

$unattend | Out-File -FilePath "$env:ProgramData\OSDCloud\Unattend.xml" -Encoding utf8 -Force
Edit-OSDCloudWinPE -Unattend "$env:ProgramData\OSDCloud\Unattend.xml" -Verbose

New-OSDCloudUSB
```

## How It Works

- **WinPE**: Hash collection script runs automatically via modified Startnet.cmd
- **First Boot**: Boots into Audit Mode automatically
- **Audit Mode**: Upload script runs automatically via Unattend FirstLogonCommands
- Script then exits to normal OOBE

All scripts run locally from the USB.

---

**This is the current recommended fully automated configuration.**