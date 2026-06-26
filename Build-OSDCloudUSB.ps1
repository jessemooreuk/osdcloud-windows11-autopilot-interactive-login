# Build-OSDCloudUSB.ps1
# LazyOSD - Fully Automated Enterprise OSD + Intune Enrollment
#
# Last Updated: 2026-06-25
#
# Credits:
#   - Built on the excellent OSD PowerShell module by OSDeploy (https://www.osdeploy.com/)
#   - Automation, enterprise workflow, and specific use case designed by Jesse Moore
#   - Script logic and refinements developed through detailed interaction with Grok (xAI)

Write-Host "=== LazyOSD - Fully Automated Enterprise Build ===" -ForegroundColor Cyan
Write-Host "Last Updated: 2026-06-25" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Credits:" -ForegroundColor Yellow
Write-Host "  - Built on the excellent OSD module by OSDeploy (https://www.osdeploy.com/)" -ForegroundColor Gray
Write-Host "  - Automation and enterprise workflow designed by Jesse Moore" -ForegroundColor Gray
Write-Host "  - Script logic developed through interaction with Grok (xAI)" -ForegroundColor Gray
Write-Host ""

$ProjectName = Read-Host "Enter Project Name (used for ISO filename)"
if ([string]::IsNullOrWhiteSpace($ProjectName)) { $ProjectName = "OSDCloud-Autopilot" }
Write-Host "Project: $ProjectName" -ForegroundColor Green

$mode = Read-Host "Show simple progress bar or verbose output? (P = Progress bar, V = Verbose)"
$UseProgressBar = ($mode.ToUpper() -eq "P")

if ($UseProgressBar) {
    Write-Host "Progress bar mode enabled." -ForegroundColor Green
} else {
    Write-Host "Verbose mode enabled." -ForegroundColor Green
}

function Write-BuildStep {
    param([string]$Message, [int]$Percent)
    if ($UseProgressBar) {
        Write-Progress -Activity "Building $ProjectName" -Status $Message -PercentComplete $Percent
    } else {
        Write-Host $Message -ForegroundColor Yellow
    }
}

# Download Audit Mode script
Write-BuildStep "Downloading Audit Mode script..." 10

$workspaceRoot = "$env:ProgramData\OSDCloud\Workspace"
New-Item -Path $workspaceRoot -ItemType Directory -Force | Out-Null

$baseUrl = "https://raw.githubusercontent.com/jessemooreuk/LazyOSD/main"

try {
    Invoke-WebRequest -Uri "$baseUrl/AuditMode-AutopilotUpload.ps1" -OutFile "$workspaceRoot\AuditMode-AutopilotUpload.ps1" -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit
}

# Create Unattend.xml in workspace
$unattendContent = @'
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
          <CommandLine>powershell -NoLogo -File "X:\AuditMode-AutopilotUpload.ps1"</CommandLine>
          <Description>Collect hash + upload to Autopilot + exit to OOBE</Description>
        </SynchronousCommand>
      </FirstLogonCommands>
    </component>
  </settings>
</unattend>
'@ 

$unattendContent | Out-File -FilePath "$workspaceRoot\Unattend.xml" -Encoding utf8 -Force

# Core setup
Write-BuildStep "Updating OSD module..." 55
Install-Module OSD -Force -AllowClobber
Import-Module OSD -Force

Write-BuildStep "Creating Template and Workspace..." 60
New-OSDCloudTemplate -WinRE
New-OSDCloudWorkspace

Write-BuildStep "Adding Intel drivers..." 70
Edit-OSDCloudWinPE -CloudDriver WiFi,IntelNet,*

# Use hosted script method (recommended in Akos Bakos article)
Write-BuildStep "Configuring automation via hosted script..." 75

$hostedScriptUrl = "https://raw.githubusercontent.com/jessemooreuk/LazyOSD/main/Start-LazyOSD.ps1"

Edit-OSDCloudWinPE -WebPSScript $hostedScriptUrl

Write-BuildStep "Finalizing WinPE..." 82
Edit-OSDCloudWinPE

# Output choice
Write-BuildStep "Build complete. Choosing output..." 88

$choice = Read-Host "Create USB, ISO, or Both? (U = USB, I = ISO, B = Both)"

switch ($choice.ToUpper()) {
    "U" { New-OSDCloudUSB }
    "I" { 
        New-OSDCloudISO
        Start-Sleep -Seconds 2
        $noPromptIso = "C:\OSDCloud\OSDCloud_NoPrompt.iso"
        if (Test-Path $noPromptIso) {
            $newName = "$ProjectName.iso"
            $destination = Join-Path "$env:USERPROFILE\Downloads" $newName
            Move-Item -Path $noPromptIso -Destination $destination -Force
            Write-Host "ISO saved as: $destination (NoPrompt version)" -ForegroundColor Green
        }
    }
    "B" { 
        New-OSDCloudUSB
        New-OSDCloudISO
        Start-Sleep -Seconds 2
        $noPromptIso = "C:\OSDCloud\OSDCloud_NoPrompt.iso"
        if (Test-Path $noPromptIso) {
            $newName = "$ProjectName.iso"
            $destination = Join-Path "$env:USERPROFILE\Downloads" $newName
            Move-Item -Path $noPromptIso -Destination $destination -Force
            Write-Host "ISO saved as: $destination (NoPrompt version)" -ForegroundColor Green
        }
    }
    default { New-OSDCloudUSB }
}

if ($UseProgressBar) { Write-Progress -Activity "Building $ProjectName" -Completed }

Write-Host "=== Build Complete ===" -ForegroundColor Green
Write-Host "Project: $ProjectName" -ForegroundColor Green
Write-Host "LazyOSD - Windows 11 24H2 Enterprise (Hosted Script Method)" -ForegroundColor Green
