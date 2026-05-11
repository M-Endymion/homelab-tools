#!/bin/bash
# =============================================================================
# Jellyfin Media Manager v1.3
# Smart Duplicate Finder + Broken File Scanner + Interactive Cleanup
# Author: M-Endymion
# =============================================================================

set -euo pipefail

MEDIA_PATH="${1:-/media}"
MODE="${2:-menu}"

REPORT_DIR="$HOME/jellyfin-reports/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT_DIR"

echo "🚀 Jellyfin Media Manager v1.3"
echo "Media Path: $MEDIA_PATH"
echo "========================================"

# =============================================================================
# Broken File Scanner
# =============================================================================
scan_broken_files() {
    echo "🩺 Scanning for broken or corrupt media files..."
    echo "This may take a while depending on your library size..."

    > "$REPORT_DIR/broken_files.txt"
    > "$REPORT_DIR/broken_summary.txt"

    find "$MEDIA_PATH" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" \) -print0 | 
    xargs -0 -I {} bash -c '
        file="{}"
        if ! ffprobe -v quiet -print_format json -show_format -show_streams "$file" > /dev/null 2>&1; then
            echo "❌ CORRUPT CONTAINER → $file" | tee -a "'"$REPORT_DIR/broken_files.txt"'"
            echo "$file" >> "'"$REPORT_DIR/broken_summary.txt"'"
        else
            # Additional checks
            duration=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$file" 2>/dev/null || echo "0")
            video_streams=$(ffprobe -v quiet -select_streams v -show_entries stream=index -of csv=p=0 "$file" 2>/dev/null | wc -l)
            
            if (( $(echo "$duration < 60" | bc -l 2>/dev/null || echo 0) )); then
                echo "⚠️  Very Short File (< 1 min) → $file" | tee -a "'"$REPORT_DIR/broken_files.txt"'"
            fi
            if [ "$video_streams" -eq 0 ]; then
                echo "⚠️  No Video Stream → $file" | tee -a "'"$REPORT_DIR/broken_files.txt"'"
            fi
        fi
    '

    local broken_count=$(wc -l < "$REPORT_DIR/broken_files.txt")
    echo "✅ Broken file scan completed. Found $broken_count issues."
}

# =============================================================================
# Interactive Duplicate Selector (Improved from before)
# =============================================================================
interactive_duplicate_cleanup() {
    echo "🔍 Scanning for duplicates with smart grouping..."

    > "$REPORT_DIR/duplicate_groups_final.txt"

    find "$MEDIA_PATH" -type f \( -iname "*.mkv" -o -iname "*.mp4" \) | 
    while read -r file; do
        filename=$(basename "$file")
        title=$(echo "$filename" | sed -E 's/\.(mkv|mp4|avi)$//i' | sed -E 's/\.[0-9]{4}.*//' | sed -E 's/\.(1080p|2160p|720p|4K|WEB|BluRay|x264|x265|HEVC).*//i' | sed 's/[._]/ /g' | awk '{$1=$1};1')
        echo "$title|$file" >> "$REPORT_DIR/duplicate_groups_final.txt"
    done

    sort "$REPORT_DIR/duplicate_groups_final.txt" | 
    awk -F'|' '{count[$1]++; files[$1]=files[$1] $2 "\n"} END {for (t in count) if (count[t]>1) print count[t] "|" t "|" files[t]}' > "$REPORT_DIR/duplicates_to_review.txt"

    echo "Found duplicate groups. Starting interactive review..."

    while IFS='|' read -r count title files; do
        [[ -z "$title" ]] && continue

        echo -e "\n══════════════════════════════════════"
        echo "🔄 Group: $title ($count versions found)"
        echo "══════════════════════════════════════"

        echo "$files" | while read -r f; do
            [[ -f "$f" ]] && echo "   $(du -h "$f" | cut -f1) | $(ffprobe -v quiet -select_streams v:0 -show_entries stream=height -of csv=p=0 "$f" 2>/dev/null || echo "?")p | $f"
        done

        echo -e "\nAction for this group?"
        echo "1) Keep best version (largest + highest res), move rest"
        echo "2) Skip"
        echo "3) Move ALL to Duplicates"
        read -r choice

        case $choice in
            1)
                best=$(echo "$files" | while read -r f; do [[ -f "$f" ]] && echo "$(stat -c %s "$f")|$f"; done | sort -nr | head -1 | cut -d'|' -f2)
                mkdir -p "$MEDIA_PATH/Duplicates/$title"
                echo "$files" | while read -r f; do
                    [[ "$f" != "$best" ]] && [[ -f "$f" ]] && mv "$f" "$MEDIA_PATH/Duplicates/$title/"
                done
                echo "✅ Kept best version."
                ;;
            3)
                mkdir -p "$MEDIA_PATH/Duplicates/$title"
                echo "$files" | while read -r f; do [[ -f "$f" ]] && mv "$f" "$MEDIA_PATH/Duplicates/$title/"; done
                echo "✅ All moved to Duplicates."
                ;;
            *) echo "Skipped." ;;
        esac
    done < "$REPORT_DIR/duplicates_to_review.txt"
}

# =============================================================================
# Main Menu
# =============================================================================
if [[ "$MODE" == "menu" || -z "$MODE" ]]; then
    echo ""
    echo "What would you like to do?"
    echo "1) Interactive Duplicate Cleanup"
    echo "2) Scan for Broken / Corrupt Files"
    echo "3) Full Scan (Duplicates + Broken)"
    echo "4) Exit"
    read -r choice

    case $choice in
        1) interactive_duplicate_cleanup ;;
        2) scan_broken_files ;;
        3) scan_broken_files; interactive_duplicate_cleanup ;;
        *) echo "Goodbye!"; exit 0 ;;
    esac
fi

echo ""
echo "✅ All done! Reports saved to: $REPORT_DIR"
