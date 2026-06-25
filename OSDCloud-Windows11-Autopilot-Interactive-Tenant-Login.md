# Automated installation of Windows 11 using OSDCloud

**Booting from a USB Stick**  
**Automatically registering in Autopilot (Tenant-Agnostic)**  
**Includes all common Intel wireless and LAN drivers**  
**OSDCloud supports WiFi Connection**

**Simplified & Reliable Workflow (Recommended)**

## Overview

This version focuses on maximum reliability:

- **WinPE**: Clean Windows 11 installation only
- **Audit Mode**: Automatically collects hardware hash + uploads to Autopilot + exits to normal OOBE

Everything important (hash collection + upload) now happens in Audit Mode (full Windows environment).

## How to Build

```powershell
irm https://raw.githubusercontent.com/jessemooreuk/osdcloud-windows11-autopilot-interactive-login/main/Build-OSDCloudUSB.ps1 | iex
```

The build script will:
- Ask for a Project Name (used for ISO filename)
- Ask if you want Progress Bar or Verbose output
- Download the Audit Mode script
- Configure automatic boot into Audit Mode
- Let you choose USB, ISO, or Both at the end

## What Happens During Deployment

1. **WinPE** → Clean Windows 11 installation (fully automatic)
2. **First Boot** → Automatically boots into **Audit Mode**
3. **Audit Mode** (automatic):
   - Prompts to connect to WiFi (if needed)
   - Collects hardware hash
   - Authenticates using Device Code Flow (tenant-agnostic)
   - Uploads device to Autopilot
   - Exits Audit Mode and reboots into normal OOBE

## Files

- `Build-OSDCloudUSB.ps1` – Main build script
- `AuditMode-AutopilotUpload.ps1` – Runs automatically in Audit Mode (collection + upload + exit to OOBE)

---

**This is currently the cleanest and most reliable workflow.**