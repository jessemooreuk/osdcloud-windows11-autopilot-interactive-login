# Autopilot-Interactive-Login.ps1
# Tenant-AGNOSTIC version for universal OSDCloud USB deployments
# Works across any Entra ID tenant - no hardcoded Tenant ID, Client ID, or Secrets

Write-Host "=== Autopilot Registration - Tenant Agnostic Mode ===" -ForegroundColor Cyan
Write-Host "This script works with ANY tenant. You will authenticate interactively." -ForegroundColor Yellow
Write-Host ""

# =============================================
# TENANT AGNOSTIC AUTHENTICATION
# =============================================

# Primary method: Device Code Flow (recommended - works across tenants)
Write-Host "Starting Device Code authentication..." -ForegroundColor Green
Write-Host "A code will be displayed. Go to https://microsoft.com/devicelogin on any device and sign in with the target tenant account."

try {
    Connect-MgGraph -UseDeviceCode -Scopes "DeviceManagementManagedDevices.ReadWrite.All" -NoWelcome
    
    Write-Host ""
    Write-Host "Successfully authenticated to tenant!" -ForegroundColor Green
    
    # Optional: Show which tenant you are connected to
    $context = Get-MgContext
    Write-Host "Connected to Tenant: $($context.TenantId)" -ForegroundColor Cyan
    
} catch {
    Write-Host "Authentication failed: $_" -ForegroundColor Red
    Write-Host "Falling back to simple credential prompt..." -ForegroundColor Yellow
    
    # Fallback: Simple credential prompt
    $creds = Get-Credential -Message "Enter UPN and password for the target tenant"
    Connect-MgGraph -Credential $creds -Scopes "DeviceManagementManagedDevices.ReadWrite.All" -NoWelcome
}

# =============================================
# COLLECT HARDWARE HASH
# =============================================
try {
    Write-Host ""
    Write-Host "Collecting Windows Autopilot hardware hash..." -ForegroundColor Green
    $hash = Get-WindowsAutoPilotInfo -OutputObject
    
    Write-Host "Hardware hash collected successfully." -ForegroundColor Green
    
    # =============================================
    # AUTOMATIC UPLOAD TO AUTOPILOT (using signed-in context)
    # =============================================
    Write-Host "Uploading device to Autopilot..." -ForegroundColor Green
    
    $body = @{
        serialNumber = $hash.SerialNumber
        productKey   = $hash.ProductKey
        hardwareHash = $hash.HardwareHash
    }
    
    # Upload using the current authenticated session (tenant-agnostic)
    Invoke-MgGraphRequest -Method POST `
        -Uri "https://graph.microsoft.com/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities" `
        -Body ($body | ConvertTo-Json -Depth 5) `
        -ContentType "application/json"
    
    Write-Host ""
    Write-Host "SUCCESS: Device has been automatically registered in Autopilot!" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "Upload to Autopilot failed: $_" -ForegroundColor Red
    Write-Host "The device will still boot into Autopilot OOBE and can be registered manually or via profile." -ForegroundColor Yellow
}

Start-Sleep -Seconds 3
Write-Host ""
Write-Host "Autopilot registration step complete. Continuing deployment..." -ForegroundColor Cyan
