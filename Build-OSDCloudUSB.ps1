# Build-OSDCloudUSB.ps1
# Fully automated OSDCloud build with progress/verbose option

Write-Host "=== OSDCloud Automated Build ===" -ForegroundColor Cyan

# Project Name
$ProjectName = Read-Host "Enter Project Name"
if ([string]::IsNullOrWhiteSpace($ProjectName)) { $ProjectName = "OSDCloud-Autopilot" }

# Progress vs Verbose choice
$mode = Read-Host "Show simple progress bar or verbose output? (P = Progress bar, V = Verbose)"
$UseProgressBar = ($mode.ToUpper() -eq "P")

if ($UseProgressBar) {
    Write-Host "Progress bar mode enabled (errors will still be shown)." -ForegroundColor Green
} else {
    Write-Host "Verbose mode enabled." -ForegroundColor Green
}

# Download scripts
if ($UseProgressBar) { Write-Progress -Activity "Build" -Status "Downloading scripts..." -PercentComplete 10 }
else { Write-Host "Downloading scripts..." -ForegroundColor Yellow }

$workspaceRoot = "$env:ProgramData\OSDCloud\Workspace"
New-Item -Path $workspaceRoot -ItemType Directory -Force | Out-Null

$baseUrl = "https://raw.githubusercontent.com/jessemooreuk/osdcloud-windows11-autopilot-interactive-login/main"

try {
    Invoke-WebRequest -Uri "$baseUrl/Collect-AutopilotHash-WinPE.ps1" -OutFile "$workspaceRoot\Collect-AutopilotHash-WinPE.ps1" -UseBasicParsing -ErrorAction Stop
    Invoke-WebRequest -Uri "$baseUrl/AuditMode-AutopilotUpload.ps1" -OutFile "$workspaceRoot\AuditMode-AutopilotUpload.ps1" -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Host "ERROR downloading scripts: $_" -ForegroundColor Red
    exit
}

if ($UseProgressBar) { Write-Progress -Activity "Build" -Status "Scripts downloaded." -PercentComplete 25 }

# Core build steps
if (-not $UseProgressBar) { Write-Host "Updating OSD module..." -ForegroundColor Yellow }
Install-Module OSD -Force -AllowClobber
Import-Module OSD -Force

if ($UseProgressBar) { Write-Progress -Activity "Build" -Status "Creating Template and Workspace..." -PercentComplete 35 }
else { Write-Host "Creating Template and Workspace..." -ForegroundColor Yellow }

New-OSDCloudTemplate -WinRE -Verbose:$(-not $UseProgressBar)
New-OSDCloudWorkspace -Name $ProjectName -Verbose:$(-not $UseProgressBar)

if ($UseProgressBar) { Write-Progress -Activity "Build" -Status "Adding drivers..." -PercentComplete 50 }
else { Write-Host "Adding Intel drivers..." -ForegroundColor Yellow }

Edit-OSDCloudWinPE -CloudDriver WiFi,IntelNet,* -Verbose:$(-not $UseProgressBar)
Edit-OSDCloudWinPE -Verbose:$(-not $UseProgressBar)

# Unattend
if ($UseProgressBar) { Write-Progress -Activity "Build" -Status "Configuring Unattend..." -PercentComplete 65 }
else { Write-Host "Configuring Unattend for Audit Mode..." -ForegroundColor Yellow }

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
          <CommandLine>powershell -NoLogo -File "X:\AuditMode-AutopilotUpload.ps1"</CommandLine>
          <Description>Run Autopilot Upload Automatically</Description>
        </SynchronousCommand>
      </FirstLogonCommands>
    </component>
  </settings>
</unattend>
'@ 

$unattend | Out-File -FilePath "$env:ProgramData\OSDCloud\Unattend.xml" -Encoding utf8 -Force
Edit-OSDCloudWinPE -Unattend "$env:ProgramData\OSDCloud\Unattend.xml" -Verbose:$(-not $UseProgressBar)

# Final output choice
if ($UseProgressBar) { Write-Progress -Activity "Build" -Status "Ready to create output..." -PercentComplete 85 }
else { Write-Host "Build steps complete." -ForegroundColor Green }

$choice = Read-Host "Create USB, ISO, or Both? (U/I/B)"

switch ($choice.ToUpper()) {
    "U" { 
        if (-not $UseProgressBar) { Write-Host "Creating USB..." -ForegroundColor Yellow }
        New-OSDCloudUSB 
    }
    "I" { 
        if (-not $UseProgressBar) { Write-Host "Creating ISO named $ProjectName..." -ForegroundColor Yellow }
        New-OSDCloudISO -Name $ProjectName 
    }
    "B" { 
        if (-not $UseProgressBar) { Write-Host "Creating USB..." -ForegroundColor Yellow }
        New-OSDCloudUSB
        if (-not $UseProgressBar) { Write-Host "Creating ISO named $ProjectName..." -ForegroundColor Yellow }
        New-OSDCloudISO -Name $ProjectName 
    }
    default { 
        if (-not $UseProgressBar) { Write-Host "Creating USB..." -ForegroundColor Yellow }
        New-OSDCloudUSB 
    }
}

if ($UseProgressBar) { 
    Write-Progress -Activity "Build" -Status "Complete" -PercentComplete 100 -Completed 
} else { 
    Write-Host "=== Build Complete ===" -ForegroundColor Green 
}

Write-Host "Project: $ProjectName" -ForegroundColor Green
