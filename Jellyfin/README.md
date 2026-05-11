# Jellyfin Tools

This folder contains tools for managing and maintaining **Jellyfin** media libraries.

---

### Scripts

| Script Name                    | Description                                                                 | Status |
|--------------------------------|-----------------------------------------------------------------------------|--------|
| `jellyfin-media-manager.sh`    | Main tool: Duplicate finder, broken file scanner, quality analyzer, and metadata report | Active |

---

### Usage

```bash
cd scripts/Jellyfin
chmod +x jellyfin-media-manager.sh

# Interactive menu (recommended)
./jellyfin-media-manager.sh /path/to/your/media

# Direct modes:
./jellyfin-media-manager.sh /path/to/media duplicates     # Smart duplicate finder
./jellyfin-media-manager.sh /path/to/media broken         # Find corrupt files
./jellyfin-media-manager.sh /path/to/media quality        # Quality analysis
./jellyfin-media-manager.sh /path/to/media metadata       # Jellyfin API metadata report
```

---

### Features

- Smart Duplicate Finder — Groups similar titles and lets you safely move unwanted versions to a Duplicates/ folder
- Broken File Scanner — Uses ffprobe to detect corrupt, incomplete, or unplayable files
- Quality Analyzer — Identifies low-quality files in high-resolution libraries
- Metadata Report — Connects to Jellyfin API to show missing posters, summaries, etc.

All operations are non-destructive by default.

---

### Requirements

- Linux server (Ubuntu/Debian recommended)
- ffprobe (from ffmpeg package)
- Jellyfin server running (for metadata report)
- Read/write access to your media folder

---

### Recommended Workflow

1. Run a full scan: ./jellyfin-media-manager.sh /media full
2. Review the generated reports in ~/jellyfin-reports/
3. Use Interactive Duplicate Cleanup to clean up versions safely
4. Use Metadata Report to identify items needing attention in Jellyfin

___

### Future Enhancements (Planned)

- Advanced interactive duplicate selector with preview
- Automatic Jellyfin library scan trigger
- Better quality scoring system
- Integration with *arr stack (Radarr/Sonarr/Lidarr)

---

***Note:*** Always review files before deleting anything from the Duplicates/ folder. These tools are designed to help you maintain a clean library safely.

---
