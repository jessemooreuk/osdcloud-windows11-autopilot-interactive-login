# AuditMode-AutopilotUpload.ps1
# Runs in Audit Mode after Windows 11 installation
# Prompts technician to connect to WiFi
# Uses Device Code Flow (tenant-agnostic)
# Uploads hardware hash to Autopilot
# Then automatically exits Audit Mode and reboots into OOBE

Write-Host "=== Autopilot Registration - Audit Mode ===" -ForegroundColor Cyan
Write-Host ""

# =============================================
# STEP 1: Prompt for WiFi Connection
# =============================================
Write-Host "Please connect to WiFi now if you are not using a wired connection." -ForegroundColor Yellow
Write-Host "Press Enter when you are connected to the internet..." -ForegroundColor Yellow
Read-Host | Out-Null

Write-Host ""
Write-Host "Proceeding with Autopilot registration..." -ForegroundColor Green

# =============================================
# STEP 2: Load hash from file (created in WinPE)
# =============================================
$hashFile = "C:\AutopilotHash.txt"

if (-not (Test-Path $hashFile)) {
    Write-Host "ERROR: $hashFile not found!" -ForegroundColor Red
    Write-Host "Please ensure the hash was collected during WinPE deployment." -ForegroundColor Red
    pause
    exit
}

try {
    $hash = Get-Content $hashFile | ConvertFrom-Json
    Write-Host "Hardware hash loaded successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to read hash file. Error: $_" -ForegroundColor Red
    pause
    exit
}

# =============================================
# STEP 3: Authenticate with Device Code Flow (Tenant Agnostic)
# =============================================
Write-Host ""
Write-Host "Starting Device Code authentication..." -ForegroundColor Yellow
Write-Host "A code will be shown. Go to https://microsoft.com/devicelogin on any device and sign in."

try {
    Connect-MgGraph -UseDeviceCode -Scopes "DeviceManagementManagedDevices.ReadWrite.All" -NoWelcome
    Write-Host "Authentication successful!" -ForegroundColor Green
} catch {
    Write-Host "Authentication failed: $_" -ForegroundColor Red
    pause
    exit
}

# =============================================
# STEP 4: Upload Device to Autopilot
# =============================================
try {
    Write-Host "Uploading device to Autopilot..." -ForegroundColor Yellow
    
    $body = @{
        serialNumber = $hash.SerialNumber
        productKey   = $hash.ProductKey
        hardwareHash = $hash.HardwareHash
    }
    
    Invoke-MgGraphRequest -Method POST `
        -Uri "https://graph.microsoft.com/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities" `
        -Body ($body | ConvertTo-Json) `
        -ContentType "application/json"
    
    Write-Host "SUCCESS: Device has been registered in Autopilot!" -ForegroundColor Green
    
} catch {
    Write-Host "Upload failed: $_" -ForegroundColor Red
    Write-Host "You can still continue to OOBE and register manually." -ForegroundColor Yellow
}

# =============================================
# STEP 5: Exit Audit Mode and Reboot into OOBE
# =============================================
Write-Host ""
Write-Host "Exiting Audit Mode and rebooting into OOBE..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

sysprep /oobe /reboot
