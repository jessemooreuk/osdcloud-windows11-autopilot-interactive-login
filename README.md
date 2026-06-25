# LazyOSD

**Lazy Out-of-the-box OSD for Enterprise**

Automated creation of a Windows 11 OSD image with automatic enrollment into Intune using a user’s M365 account.

**Repository:** https://github.com/jessemooreuk/LazyOSD

## Credit

LazyOSD is built on top of the outstanding work by **OSDeploy** and their excellent [OSD](https://www.osdeploy.com/) PowerShell module. 

This project simply adds automation and a specific enterprise-focused workflow on top of their foundation.

## What is LazyOSD?

LazyOSD is a simplified, automated method of building a fully functional OSD (Operating System Deployment) image using OSDCloud.

It is designed for enterprise environments where you want:

- A clean Windows 11 installation
- Automatic boot into Audit Mode
- Automatic hardware hash collection + upload to Intune/Autopilot
- Zero-touch or minimal-touch experience for technicians

## Key Features

- Windows 11 24H2 Enterprise (latest)
- Fully automatic installation
- Automatic Intune/Autopilot enrollment via M365 login (Device Code Flow)
- Intel Wireless + LAN drivers included
- WiFi support in WinPE
- Simple one-command build process

## Quick Start

```powershell
irm https://raw.githubusercontent.com/jessemooreuk/LazyOSD/main/Build-OSDCloudUSB.ps1 | iex
```

## Workflow

1. Build the USB/ISO using the one-liner above
2. Boot the media → Windows 11 installs automatically
3. Device boots into Audit Mode automatically
4. Hardware hash is collected and uploaded to Intune/Autopilot
5. Device exits Audit Mode and continues to normal OOBE

## Project Goal

Make enterprise OSD as simple and automated as possible while keeping it flexible and tenant-agnostic.

---

**LazyOSD** – Because deploying Windows shouldn’t be painful.