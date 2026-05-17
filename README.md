<div align="center">
  <img src="https://raw.githubusercontent.com/M-Endymion/homelab-tools/main/thumbnail-homelab.png" alt="Homelab Tools Banner" width="100%" />
</div>

<br>

# Homelab Tools

**Practical scripts for self-hosted services, media servers, and quick server deployments**

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Shell](https://img.shields.io/badge/Shell-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Jellyfin](https://img.shields.io/badge/Jellyfin-00A4DC?style=for-the-badge&logo=jellyfin&logoColor=white)

---

## Current Tools

| Tool / Folder                  | Description                                                                 | Focus Area          |
|--------------------------------|-----------------------------------------------------------------------------|---------------------|
| **`Ubuntu-Server-QuickDeploy.sh`** | One-command setup: Docker + Portainer + Tailscale + Watchtower + Fail2Ban   | Server Provisioning |
| **`jellyfin-media-manager.sh`**    | Smart duplicate finder, broken file scanner, quality analyzer, metadata reports | Media Server Management |

---

## Quick Start

### Ubuntu Server Quick Deploy
```bash
curl -sSL https://raw.githubusercontent.com/M-Endymion/homelab-tools/main/Ubuntu/Ubuntu-Server-QuickDeploy.sh -o deploy.sh
chmod +x deploy.sh
sudo ./deploy.sh
```

---

### Jellyfin Media Manager
```bash
cd Jellyfin
chmod +x jellyfin-media-manager.sh
./jellyfin-media-manager.sh /path/to/your/media/library
```

---

## Key Features

### Ubuntu Quick Deploy

- Full Docker + Portainer web UI
- Tailscale VPN for secure remote access
- Watchtower for automatic container updates
- Fail2Ban security hardening
- Designed for fast, repeatable homelab server builds

### Jellyfin Media Manager

- Intelligent duplicate detection (safe deletion options)
- Broken/corrupt file detection (via ffprobe)
- Quality analysis (low-res files in high-res folders, old codecs, etc.)
- Jellyfin API integration for metadata reporting

___

### Philosophy

- Safe by default — no automatic destructive actions without confirmation
- Focused on real-world homelab use cases
- Clean, well-documented, and easy to maintain
- Cross-platform friendly (Linux + macOS)

___

### Future Plans

- Better Jellyfin duplicate cleanup UI
- *arr stack integration tools
- Monitoring stack (Prometheus + Grafana)
- Backup & restore helpers
- Additional one-click service deployers

---

### About the Author
**Jason Ray (M-Endymion)**

IT Professional specializing in MECM/SCCM, automation, and hybrid endpoint management.

This repository showcases my practical scripting skills for self-hosted infrastructure and media servers — skills that translate directly into enterprise automation and DevOps work.

- LinkedIn: Jason Ray
- Open to opportunities in Endpoint Management, Automation, and Infrastructure roles

**Last Updated: May 17, 2026**

---

**Note:** Always review scripts before running and test in a safe environment first.

---
