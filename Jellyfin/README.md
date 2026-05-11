# Jellyfin Media Manager

A powerful, safe toolkit for maintaining clean, high-quality Jellyfin media libraries.

---

### Main Script

**`jellyfin-media-manager.sh`** (v1.7)

---

### Features

| Feature                        | Description                                                                 | Status |
|--------------------------------|-----------------------------------------------------------------------------|--------|
| **Interactive Duplicate Finder** | Smart grouping by title, side-by-side comparison, safe move to `Duplicates/` folder | Complete |
| **Broken File Scanner**        | Detects corrupt, incomplete, or unplayable files using `ffprobe`           | Complete |
| **Quality Analyzer**           | Identifies low-quality files (old codecs, low-res in high-res folders, etc.) | Complete |
| ***arr Integration**           | Triggers search commands in Radarr (and soon Sonarr) for broken/low-quality items | Complete |
| **Metadata Report**            | Basic Jellyfin API report (missing posters, summaries, etc.)                | Basic |

---

### Usage

```bash
chmod +x jellyfin-media-manager.sh

# Recommended - Interactive Menu
./jellyfin-media-manager.sh /path/to/your/media

# Direct modes:
./jellyfin-media-manager.sh /path/to/media duplicates    # Duplicate cleanup
./jellyfin-media-manager.sh /path/to/media broken        # Broken file scan + *arr search
./jellyfin-media-manager.sh /path/to/media quality       # Quality analysis
./jellyfin-media-manager.sh /path/to/media full          # Full analysis
```

---

### Features

- Smart Duplicate Finder — Groups similar titles and lets you safely move unwanted versions to a Duplicates/ folder
- Broken File Scanner — Uses ffprobe to detect corrupt, incomplete, or unplayable files
- Quality Analyzer — Identifies low-quality files in high-resolution libraries
- Metadata Report — Connects to Jellyfin API to show missing posters, summaries, etc.

### Key Highlight: *arr Integration
When the script finds broken or low-quality files, it will ask if you want to trigger a search in Radarr right away. This allows you to quickly replace bad files using your existing *arr setup without manual searching.

All operations are non-destructive by default.

---

### Requirements

- Linux server (Ubuntu/Debian recommended)
- ```ffmpeg``` (for ```ffprobe```)
- Jellyfin server URL + API key (for metadata report)
- Read/write access to your media folder

---

### Example Workflow

1. Run a full analysis:
   ```./jellyfin-media-manager.sh /media full```
2. Review reports in ```~/jellyfin-reports/```
3. Use Interactive Duplicate Cleanup to safely organize multiple versions
4. Use Broken File Scanner to find corrupt files
5. Run Metadata Report to see what needs attention in Jellyfin

---

### Safety First

- No files are ever deleted automatically
- Duplicates are moved to a Duplicates/ folder (easy to recover)
- All operations are logged
- You remain in full control
___

### Future Enhancements (Planned)

- Advanced interactive duplicate selector with preview
- Automatic Jellyfin library scan trigger
- Better quality scoring system
- Integration with *arr stack (Radarr/Sonarr/Lidarr)

---

***Note:*** Always review files before deleting anything from the Duplicates/ folder. This tool was built to solve real-world Jellyfin library management problems safely and efficiently.

---
