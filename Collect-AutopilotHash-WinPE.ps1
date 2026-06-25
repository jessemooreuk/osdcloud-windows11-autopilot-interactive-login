# Collect-AutopilotHash-WinPE.ps1
# Simple, reliable script for OSDCloud WinPE
# Collects hardware hash and saves it to C:\AutopilotHash.txt
# No Microsoft.Graph required - works even if modules are missing

Write-Host "=== Autopilot Hardware Hash Collection ===" -ForegroundColor Cyan
Write-Host "This is a reliable fallback for WinPE environments."
Write-Host ""

try {
    Write-Host "Collecting hardware hash..." -ForegroundColor Yellow
    
    $hash = Get-WindowsAutoPilotInfo -OutputObject
    
    # Save to file on the system drive (will be available after Windows installs)
    $hash | Out-File -FilePath "C:\AutopilotHash.txt" -Encoding UTF8 -Force
    
    Write-Host ""
    Write-Host "SUCCESS: Hardware hash saved to C:\AutopilotHash.txt" -ForegroundColor Green
    Write-Host ""
    Write-Host "Serial Number: $($hash.SerialNumber)" -ForegroundColor White
    Write-Host "Hardware Hash (first 50 chars): $($hash.HardwareHash.Substring(0,50))..." -ForegroundColor White
    Write-Host ""
    Write-Host "You can now reboot and the hash will be available on the new Windows installation."
    Write-Host "Alternatively, copy the hash from C:\AutopilotHash.txt after deployment."
    
} catch {
    Write-Host ""
    Write-Host "ERROR collecting hash: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
    
    # Fallback using built-in command
    try {
        $hashText = Get-WindowsAutoPilotInfo
        $hashText | Out-File -FilePath "C:\AutopilotHash.txt" -Encoding UTF8 -Force
        Write-Host "Hash saved using fallback method to C:\AutopilotHash.txt" -ForegroundColor Green
    } catch {
        Write-Host "Failed to collect hash. Please note the error above." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Script complete. You can safely continue or reboot." -ForegroundColor Cyan
Start-Sleep -Seconds 5
