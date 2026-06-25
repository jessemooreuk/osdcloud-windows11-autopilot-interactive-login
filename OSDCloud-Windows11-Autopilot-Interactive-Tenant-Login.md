# Automated installation of Windows 11 using OSDCloud

**Booting from a USB Stick**  
**Automatically registering in Autopilot (Tenant-Agnostic)**  
**Includes all common Intel wireless and LAN drivers**  
**OSDCloud supports WiFi Connection**

**Universal / Tenant-Agnostic Version** (June 2026)

This guide creates a **single universal OSDCloud USB** that works with **any Entra ID tenant**.

## Prerequisites
- Windows 10 (1703+) or Windows 11 PC with administrator rights and internet
- USB flash drive (16 GB+ recommended)

## Step 1: Install / Update the OSD Module

```powershell
Install-Module OSD -Force -AllowClobber -Verbose
Import-Module OSD -Force
```

## Step 2: Create OSDCloud Template with WinRE

```powershell
New-OSDCloudTemplate -WinRE -Verbose
```

## Step 3: Create the Workspace

```powershell
New-OSDCloudWorkspace -Verbose
```

## Step 4: Add All Common Intel Wireless + LAN Drivers

```powershell
Edit-OSDCloudWinPE -CloudDriver WiFi,IntelNet,* -Verbose
```

## Step 5: Pre-stage Microsoft.Graph Module (Required for Automatic Upload)

To enable full automatic Autopilot hash upload via Graph in WinPE, you must pre-install the Microsoft.Graph modules into the WinPE image.

Run this command **after** creating the workspace:

```powershell
Edit-OSDCloudWinPE -Module Microsoft.Graph.Authentication, Microsoft.Graph.DeviceManagement -Verbose
```

> **Note**: This will increase the size of your WinPE image. If space is a concern, you can try just `Microsoft.Graph.Authentication` first.

## Step 6: Add the Tenant-Agnostic Autopilot Script

```powershell
Edit-OSDCloudWinPE -WebPSScript https://raw.githubusercontent.com/jessemooreuk/osdcloud-windows11-autopilot-interactive-login/main/Autopilot-Interactive-Login.ps1 -Verbose
```

## Step 7: Build the USB

```powershell
New-OSDCloudUSB
```

## Step 8: Boot & Deploy

The script will now be able to use `Connect-MgGraph` and upload the device automatically after the technician authenticates via Device Code Flow.

## Making It Tenant Agnostic

The current script uses only interactive Device Code Flow. No Tenant ID or secrets are stored in the USB.

## Troubleshooting No Output

If you still see no prompt after `Invoke-WebPSScript`, run this manually in WinPE:

```powershell
powershell -NoLogo -Command "Invoke-WebPSScript 'https://raw.githubusercontent.com/jessemooreuk/osdcloud-windows11-autopilot-interactive-login/main/Autopilot-Interactive-Login.ps1' -Verbose"
```

---

**You now have a complete universal solution** with pre-staged Graph support for automatic Autopilot registration.