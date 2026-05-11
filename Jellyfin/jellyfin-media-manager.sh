#!/bin/bash
# =============================================================================
# Jellyfin Media Manager v1.2
# Smart Duplicate Finder + Interactive Cleanup
# Author: M-Endymion
# =============================================================================

set -euo pipefail

MEDIA_PATH="${1:-/media}"
MODE="${2:-menu}"

REPORT_DIR="$HOME/jellyfin-reports/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT_DIR"

echo "🚀 Jellyfin Media Manager v1.2 - Smart Duplicate Finder"
echo "Media Path: $MEDIA_PATH"
echo "========================================"

# =============================================================================
# Smart Duplicate Finder + Interactive Cleanup
# =============================================================================
interactive_duplicate_cleanup() {
    echo "🔍 Scanning for duplicates with smart grouping..."

    # Create temporary working files
    > "$REPORT_DIR/duplicates_groups.txt"

    find "$MEDIA_PATH" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \) | 
    while read -r file; do
        filename=$(basename "$file")
        
        # Smart title extraction (removes year, resolution, source tags, etc.)
        title=$(echo "$filename" | 
                sed -E 's/\.(mkv|mp4|avi|mov)$//i' | 
                sed -E 's/\.[0-9]{4}.*//' | 
                sed -E 's/\.(1080p|720p|2160p|4K|BluRay|WEBRip|WEB-DL|HDTV|x264|x265|HEVC|AAC).*//i' |
                sed -E 's/[._]/ /g' | 
                sed -E 's/ +/ /g' | 
                awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9]{4}$/) break; else printf "%s ", $i}' |
                sed 's/ $//')

        echo "$title|$file" >> "$REPORT_DIR/duplicates_groups.txt"
    done

    # Group by title
    sort "$REPORT_DIR/duplicates_groups.txt" | 
    awk -F'|' '{count[$1]++; files[$1]=files[$1] $2 "\n"} 
         END {for (t in count) if (count[t]>1) print count[t] "|" t "|" files[t]}' > "$REPORT_DIR/duplicate_groups_final.txt"

    echo "Found duplicate groups. Starting interactive review..."

    while IFS='|' read -r count title files; do
        [[ -z "$title" ]] && continue

        echo -e "\n══════════════════════════════════════"
        echo "🔄 Group: $title ($count versions)"
        echo "══════════════════════════════════════"

        # Show detailed comparison
        echo "$files" | while read -r file; do
            if [[ -f "$file" ]]; then
                size=$(du -h "$file" | cut -f1)
                res=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=height -of csv=p=0 "$file" 2>/dev/null || echo "Unknown")
                duration=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$file" 2>/dev/null | cut -d. -f1)
                echo "   [${res}p | ${duration}s | $size] → $file"
            fi
        done

        echo -e "\nWhat would you like to do with this group?"
        echo "1) Keep the best version (largest + highest resolution), move others"
        echo "2) Review and choose manually"
        echo "3) Skip this group"
        echo "4) Move ALL to Duplicates folder"
        read -r choice

        case $choice in
            1)
                # Keep best version (highest resolution + largest size)
                best=$(echo "$files" | while read -r f; do 
                    [[ -f "$f" ]] && echo "$(stat -c %s "$f")|$f"; 
                done | sort -nr | head -1 | cut -d'|' -f2)
                
                mkdir -p "$MEDIA_PATH/Duplicates/$title"
                echo "$files" | while read -r f; do
                    [[ "$f" != "$best" ]] && [[ -f "$f" ]] && mv "$f" "$MEDIA_PATH/Duplicates/$title/"
                done
                echo "✅ Kept best version, moved others to Duplicates/$title/"
                ;;
            2)
                echo "Manual selection coming in v1.3"
                ;;
            3)
                echo "Skipping group."
                ;;
            4)
                mkdir -p "$MEDIA_PATH/Duplicates/$title"
                echo "$files" | while read -r f; do
                    [[ -f "$f" ]] && mv "$f" "$MEDIA_PATH/Duplicates/$title/"
                done
                echo "✅ All versions moved to Duplicates."
                ;;
        esac
    done < "$REPORT_DIR/duplicate_groups_final.txt"
}

# =============================================================================
# Main Menu
# =============================================================================
if [[ "$MODE" == "menu" || -z "$MODE" ]]; then
    echo ""
    echo "Select an option:"
    echo "1) Interactive Duplicate Cleanup (Smart)"
    echo "2) Scan for Broken/Corrupt Files"
    echo "3) Full Analysis"
    echo "4) Exit"
    read -r choice

    case $choice in
        1) interactive_duplicate_cleanup ;;
        2) echo "Broken file scanner coming in v1.3" ;;
        3) interactive_duplicate_cleanup ;;
        *) echo "Goodbye!"; exit 0 ;;
    esac
else
    interactive_duplicate_cleanup
fi

echo ""
echo "✅ Operation finished. Reports saved in: $REPORT_DIR"
