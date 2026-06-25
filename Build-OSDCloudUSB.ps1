# Build-OSDCloudUSB.ps1
# Fully automated OSDCloud build with Project Name and output choice

Write-Host "=== OSDCloud Automated Build ===" -ForegroundColor Cyan

# Ask for Project Name
$ProjectName = Read-Host "Enter Project Name (used for Workspace, USB label and ISO name)"
if ([string]::IsNullOrWhiteSpace($ProjectName)) { $ProjectName = "OSDCloud-Autopilot" }

Write-Host "Project: $ProjectName" -ForegroundColor Green

# Download required scripts
Write-Host "Downloading scripts..." -ForegroundColor Yellow

$workspaceRoot = "$env:ProgramData\OSDCloud\Workspace"
New-Item -Path $workspaceRoot -ItemType Directory -Force | Out-Null

$baseUrl = "https://raw.githubusercontent.com/jessemooreuk/osdcloud-windows11-autopilot-interactive-login/main"

Invoke-WebRequest -Uri "$baseUrl/Collect-AutopilotHash-WinPE.ps1" -OutFile "$workspaceRoot\Collect-AutopilotHash-WinPE.ps1" -UseBasicParsing
Invoke-WebRequest -Uri "$baseUrl/AuditMode-AutopilotUpload.ps1" -OutFile "$workspaceRoot\AuditMode-AutopilotUpload.ps1" -UseBasicParsing

Write-Host "Scripts downloaded." -ForegroundColor Green

# Standard build steps
Install-Module OSD -Force -AllowClobber
Import-Module OSD -Force

New-OSDCloudTemplate -WinRE -Verbose
New-OSDCloudWorkspace -Name $ProjectName -Verbose

Edit-OSDCloudWinPE -CloudDriver WiFi,IntelNet,* -Verbose
Edit-OSDCloudWinPE -Verbose

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
          <CommandLine>powershell -NoLogo -File "X:\AuditMode-AutopilotUpload.ps1"</CommandLine>
          <Description>Run Autopilot Upload Automatically</Description>
        </SynchronousCommand>
      </FirstLogonCommands>
    </component>
  </settings>
</unattend>
'@ 

$unattend | Out-File -FilePath "$env:ProgramData\OSDCloud\Unattend.xml" -Encoding utf8 -Force
Edit-OSDCloudWinPE -Unattend "$env:ProgramData\OSDCloud\Unattend.xml" -Verbose

# Ask what output the user wants
Write-Host ""
$choice = Read-Host "Create USB, ISO, or Both? (U = USB, I = ISO, B = Both)"

switch ($choice.ToUpper()) {
    "U" { 
        Write-Host "Creating USB..." -ForegroundColor Yellow
        New-OSDCloudUSB 
    }
    "I" { 
        Write-Host "Creating ISO named $ProjectName..." -ForegroundColor Yellow
        New-OSDCloudISO -Name $ProjectName 
    }
    "B" { 
        Write-Host "Creating USB..." -ForegroundColor Yellow
        New-OSDCloudUSB
        Write-Host "Creating ISO named $ProjectName..." -ForegroundColor Yellow
        New-OSDCloudISO -Name $ProjectName 
    }
    default { 
        Write-Host "Creating USB..." -ForegroundColor Yellow
        New-OSDCloudUSB 
    }
}

Write-Host "=== Build Complete ===" -ForegroundColor Green
Write-Host "Project: $ProjectName" -ForegroundColor Green
