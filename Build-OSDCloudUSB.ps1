# Build-OSDCloudUSB.ps1
# LazyOSD - Fully Automated Enterprise OSD + Intune Enrollment

Write-Host "=== LazyOSD - Fully Automated Build ===" -ForegroundColor Cyan

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

# Stronger ZTI configuration for Windows 11 24H2 Enterprise
Write-BuildStep "Configuring Windows 11 24H2 Enterprise deployment..." 75
Start-OSDCloud -OSVersion 'Windows 11' -OSBuild '24H2' -OSEdition 'Enterprise' -ZTI -SkipRecoveryPartition -SkipBitlocker

Write-BuildStep "Finalizing WinPE..." 82
Edit-OSDCloudWinPE

# Make Start-OSDCloud run automatically on boot
Write-BuildStep "Enabling full automation on boot..." 88

$startnetFile = Get-ChildItem -Path "$env:ProgramData\OSDCloud\Template" -Recurse -Filter "Startnet.cmd" | Select-Object -First 1 -ExpandProperty FullName

if ($startnetFile) {
    Add-Content -Path $startnetFile -Value "powershell -NoLogo -Command \"Start-OSDCloud -OSVersion 'Windows 11' -OSBuild '24H2' -OSEdition 'Enterprise' -ZTI -SkipRecoveryPartition -SkipBitlocker\""
    Write-Host "Automation enabled in Startnet.cmd" -ForegroundColor Green
}

# Output choice
Write-BuildStep "Build complete. Choosing output..." 92

$choice = Read-Host "Create USB, ISO, or Both? (U = USB, I = ISO, B = Both)"

switch ($choice.ToUpper()) {
    "U" { New-OSDCloudUSB }
    "I" { 
        New-OSDCloudISO
        Start-Sleep -Seconds 2
        $latestIso = Get-ChildItem -Path "C:\OSDCloud" -Filter "*.iso" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latestIso) {
            $newName = "$ProjectName.iso"
            $destination = Join-Path "$env:USERPROFILE\Downloads" $newName
            Move-Item -Path $latestIso.FullName -Destination $destination -Force
            Write-Host "ISO saved as: $destination" -ForegroundColor Green
        }
    }
    "B" { 
        New-OSDCloudUSB
        New-OSDCloudISO
        Start-Sleep -Seconds 2
        $latestIso = Get-ChildItem -Path "C:\OSDCloud" -Filter "*.iso" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latestIso) {
            $newName = "$ProjectName.iso"
            $destination = Join-Path "$env:USERPROFILE\Downloads" $newName
            Move-Item -Path $latestIso.FullName -Destination $destination -Force
            Write-Host "ISO saved as: $destination" -ForegroundColor Green
        }
    }
    default { New-OSDCloudUSB }
}

if ($UseProgressBar) { Write-Progress -Activity "Building $ProjectName" -Completed }

Write-Host "=== Build Complete ===" -ForegroundColor Green
Write-Host "Project: $ProjectName" -ForegroundColor Green
Write-Host "LazyOSD - Windows 11 24H2 Enterprise (Fully Automatic + Audit Mode)" -ForegroundColor Green
