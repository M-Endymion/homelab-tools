<div align="center">
  <img src="https://raw.githubusercontent.com/M-Endymion/homelab-tools/main/thumbnail-homelab.png" alt="Homelab Tools Banner" />
</div>

<br>

# Homelab Tools

A collection of practical scripts and tools for self-hosted services, media servers, and home infrastructure.

Maintained by **M-Endymion**.

---

## Current Tools

| Folder / Tool                    | Description                                                                 | Focus Area |
|----------------------------------|-----------------------------------------------------------------------------|------------|
| **Jellyfin**                     | Media library management tools                                              | Media Server |
| `jellyfin-media-manager.sh`      | Smart duplicate finder, broken file scanner, quality analyzer, metadata report | Jellyfin |
| **Ubuntu**                       | Ubuntu Server quick deployment scripts                                      | Server Setup |
| `Ubuntu-Server-QuickDeploy.sh`   | Docker + Portainer + Tailscale + Watchtower + Fail2Ban                      | Homelab Servers |

---

## Purpose

This repository contains tools I use for managing my homelab and self-hosted services. The focus is on:

- Making server setup fast and repeatable
- Keeping media libraries clean and high-quality
- Providing useful utilities for common homelab tasks
- Cross-platform support (Linux + macOS)

---

## Quick Start

## Jellyfin Media Manager
```bash
cd Jellyfin
chmod +x jellyfin-media-manager.sh
./jellyfin-media-manager.sh /path/to/media
```

___

## Features Overview
### Jellyfin Tools

- Smart duplicate detection and safe cleanup
-Broken/corrupt file detection using ffprobe
--Quality analysis (low-res in high-res folders, old codecs, etc.)
- Jellyfin API metadata reporting

### Ubuntu Tools

- One-command setup for new servers
- Docker + Portainer
- Tailscale VPN
- Watchtower (auto-updates)
- Fail2Ban security

___

## Philosophy

- Safe by default — no automatic destructive actions
- Well-documented and easy to understand
- Focused on real-world homelab use cases

___

### Future Plans

- More Jellyfin tools (better duplicate UI, integration with *arr stack)
- Monitoring stack (Prometheus + Grafana)
- Backup solutions
- Additional self-hosted service deployers

---
