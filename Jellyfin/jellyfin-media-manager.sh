#!/bin/bash
# =============================================================================
# Jellyfin Media Manager
# Duplicate Finder + Interactive Cleanup + Quality Checker + Broken File Detector
# Author: M-Endymion
# Version: 1.1
# =============================================================================

set -euo pipefail

MEDIA_PATH="${1:-/media}"
MODE="${2:-menu}"   # menu, duplicates, quality, broken, interactive

REPORT_DIR="$HOME/jellyfin-reports/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT_DIR"

echo "🚀 Jellyfin Media Manager v1.1"
echo "Media Path: $MEDIA_PATH"
echo "========================================"

# =============================================================================
# Interactive Duplicate Selector
# =============================================================================
interactive_duplicate_cleanup() {
    echo "🔍 Scanning for duplicate files (this may take a while)..."

    # Find all video files and group by title + year
    find "$MEDIA_PATH" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \) | 
    while read -r file; do
        # Extract title and year from filename (common patterns)
        basename "$file" | sed -E 's/\.(mkv|mp4|avi)$//i' | sed -E 's/\.[0-9]{4}.*//'
    done | sort | uniq -c | sort -nr | head -50 > "$REPORT_DIR/duplicate_groups.txt"

    echo "Found potential duplicate groups. Starting interactive cleanup..."

    while IFS= read -r line; do
        count=$(echo "$line" | awk '{print $1}')
        title=$(echo "$line" | cut -d' ' -f2-)
        
        if [[ $count -gt 1 ]]; then
            echo -e "\n🔄 Found $count versions of: $title"
            find "$MEDIA_PATH" -type f -iname "*$title*" \( -iname "*.mkv" -o -iname "*.mp4" \) | 
            while read -r file; do
                size=$(du -h "$file" | cut -f1)
                res=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=height -of csv=p=0 "$file" 2>/dev/null || echo "Unknown")
                echo "   - $size | ${res}p | $file"
            done

            echo -e "\nWhat would you like to do?"
            echo "1) Keep the largest/best version and move others to Duplicates/"
            echo "2) Skip this group"
            echo "3) Move all to Duplicates/ (rare)"
            read -r choice

            case $choice in
                1)
                    # Keep largest file, move others
                    best=$(find "$MEDIA_PATH" -type f -iname "*$title*" \( -iname "*.mkv" -o -iname "*.mp4" \) -exec du -b {} + | sort -nr | head -1 | cut -f2)
                    mkdir -p "$MEDIA_PATH/Duplicates/$title"
                    find "$MEDIA_PATH" -type f -iname "*$title*" \( -iname "*.mkv" -o -iname "*.mp4" \) ! -path "$best" -exec mv {} "$MEDIA_PATH/Duplicates/$title/" \;
                    echo "✅ Kept best version, moved others."
                    ;;
                2)
                    echo "Skipping..."
                    ;;
                3)
                    mkdir -p "$MEDIA_PATH/Duplicates/$title"
                    find "$MEDIA_PATH" -type f -iname "*$title*" \( -iname "*.mkv" -o -iname "*.mp4" \) -exec mv {} "$MEDIA_PATH/Duplicates/$title/" \;
                    echo "✅ All versions moved to Duplicates."
                    ;;
            esac
        fi
    done < "$REPORT_DIR/duplicate_groups.txt"
}

# =============================================================================
# Other Modes (Basic for now)
# =============================================================================
find_broken_files() {
    echo "🩺 Scanning for broken media files..."
    find "$MEDIA_PATH" -type f \( -iname "*.mkv" -o -iname "*.mp4" \) -print0 | 
    xargs -0 -I {} bash -c '
        if ! ffprobe -v quiet -print_format json -show_format -show_streams "{}" > /dev/null 2>&1; then
            echo "❌ CORRUPT: {}" | tee -a "'"$REPORT_DIR/broken_files.txt"'"
        fi
    '
}

# =============================================================================
# Main Menu
# =============================================================================
if [[ "$MODE" == "menu" ]]; then
    echo ""
    echo "Please choose an option:"
    echo "1) Interactive Duplicate Cleanup (Recommended)"
    echo "2) Scan for Broken Files"
    echo "3) Full Scan (All Checks)"
    echo "4) Exit"
    read -r choice

    case $choice in
        1) interactive_duplicate_cleanup ;;
        2) find_broken_files ;;
        3) find_broken_files; interactive_duplicate_cleanup ;;
        *) echo "Exiting..."; exit 0 ;;
    esac
else
    interactive_duplicate_cleanup
fi

echo ""
echo "✅ Operation completed! Reports saved to: $REPORT_DIR"
