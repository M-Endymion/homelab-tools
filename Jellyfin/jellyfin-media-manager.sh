#!/bin/bash
# =============================================================================
# Jellyfin Media Manager
# Duplicate Finder, Quality Analyzer, and Broken File Detector
# Author: M-Endymion
# Version: 1.0
# =============================================================================

set -euo pipefail

MEDIA_PATH="${1:-/media}"
MODE="${2:-scan}"   # scan, duplicates, quality, broken, interactive

echo "🚀 Jellyfin Media Manager"
echo "Media Path: $MEDIA_PATH"
echo "Mode: $MODE"
echo "========================================"

# Check for required tools
command -v ffprobe >/dev/null 2>&1 || { echo "❌ ffprobe not found. Install ffmpeg"; exit 1; }

REPORT_DIR="$HOME/jellyfin-reports/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT_DIR"

# =============================================================================
# Functions
# =============================================================================

scan_duplicates() {
    echo "🔍 Scanning for potential duplicates..."
    find "$MEDIA_PATH" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \) | 
    while read -r file; do
        dirname "$file"
    done | sort | uniq -c | sort -nr | head -20
}

analyze_quality() {
    echo "📊 Analyzing media quality..."
    # This will be expanded in next iterations
    echo "Quality analysis report will be generated in: $REPORT_DIR"
}

find_broken_files() {
    echo "🩺 Scanning for broken/corrupt files..."
    find "$MEDIA_PATH" -type f \( -iname "*.mkv" -o -iname "*.mp4" \) -print0 | 
    xargs -0 -I {} bash -c '
        if ! ffprobe -v quiet -print_format json -show_format -show_streams "{}" > /dev/null 2>&1; then
            echo "❌ CORRUPT: {}"
            echo "{}" >> "'"$REPORT_DIR/broken_files.txt"'"
        fi
    '
}

interactive_duplicate_cleanup() {
    echo "🗑️  Interactive Duplicate Cleanup (Safe Mode)"
    echo "This will only MOVE files to a Duplicates folder."
    # Placeholder for interactive logic in v1.1
    echo "Interactive mode coming in next update."
}

# =============================================================================
# Main Logic
# =============================================================================

case "$MODE" in
    scan)
        echo "Running full scan..."
        find_broken_files
        analyze_quality
        ;;
    duplicates)
        scan_duplicates
        ;;
    quality)
        analyze_quality
        ;;
    broken)
        find_broken_files
        ;;
    interactive)
        interactive_duplicate_cleanup
        ;;
    *)
        echo "Usage: $0 <media_path> [scan|duplicates|quality|broken|interactive]"
        ;;
esac

echo ""
echo "✅ Scan completed! Reports saved to: $REPORT_DIR"
