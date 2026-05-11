#!/bin/bash
# =============================================================================
# Jellyfin Media Manager v1.5 - Final
# Smart Duplicate Finder + Broken Scanner + Quality Analyzer + Metadata Report
# Author: M-Endymion
# =============================================================================

set -euo pipefail

MEDIA_PATH="${1:-/media}"
MODE="${2:-menu}"

REPORT_DIR="$HOME/jellyfin-reports/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT_DIR"

echo "🚀 Jellyfin Media Manager v1.5"
echo "Media Path : $MEDIA_PATH"
echo "Reports    : $REPORT_DIR"
echo "========================================"

# =============================================================================
# 1. Interactive Duplicate Cleanup
# =============================================================================
interactive_duplicate_cleanup() {
    echo "🔍 Scanning for duplicates with smart grouping..."

    > "$REPORT_DIR/duplicates_to_review.txt"

    find "$MEDIA_PATH" -type f \( -iname "*.mkv" -o -iname "*.mp4" \) | 
    while read -r file; do
        title=$(basename "$file" | sed -E 's/\.(mkv|mp4|avi)$//i' \
                                  | sed -E 's/\.[0-9]{4}.*//' \
                                  | sed -E 's/\.(1080p|2160p|720p|4K|WEB|BluRay|x264|x265|HEVC).*//i' \
                                  | sed 's/[._]/ /g' | awk '{$1=$1};1')
        echo "$title|$file"
    done | sort | 
    awk -F'|' '{count[$1]++; files[$1]=files[$1] $2 "\n"} END {for (t in count) if (count[t]>1) print count[t] "|" t "|" files[t]}' > "$REPORT_DIR/duplicates_to_review.txt"

    echo "Found duplicate groups. Starting interactive review..."

    while IFS='|' read -r count title files; do
        [[ -z "$title" ]] && continue

        echo -e "\n══════════════════════════════════════"
        echo "🔄 Group: $title ($count versions)"
        echo "══════════════════════════════════════"

        echo "$files" | while read -r f; do
            if [[ -f "$f" ]]; then
                size=$(du -h "$f" | cut -f1)
                res=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=height -of csv=p=0 "$f" 2>/dev/null || echo "?")
                echo "   [${res}p | $size] → $f"
            fi
        done

        echo -e "\nAction?"
        echo "1) Keep best (largest + highest res), move rest"
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
                echo "✅ All moved."
                ;;
            *) echo "Skipped." ;;
        esac
    done < "$REPORT_DIR/duplicates_to_review.txt"
}

# =============================================================================
# 2. Broken File Scanner
# =============================================================================
scan_broken_files() {
    echo "🩺 Scanning for broken/corrupt files..."
    > "$REPORT_DIR/broken_files.txt"

    find "$MEDIA_PATH" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \) -print0 | 
    xargs -0 -I {} bash -c '
        file="{}"
        if ! ffprobe -v quiet -print_format json -show_format -show_streams "$file" > /dev/null 2>&1; then
            echo "❌ CORRUPT → $file" | tee -a "'"$REPORT_DIR/broken_files.txt"'"
        fi
    '
    echo "✅ Broken scan complete. Found $(wc -l < "$REPORT_DIR/broken_files.txt") issues."
}

# =============================================================================
# 3. Quality Analyzer
# =============================================================================
analyze_quality() {
    echo "📊 Running Quality Analysis..."
    > "$REPORT_DIR/low_quality_files.txt"

    find "$MEDIA_PATH" -type f \( -iname "*.mkv" -o -iname "*.mp4" \) -print0 | 
    xargs -0 -I {} bash -c '
        file="{}"
        res=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=height -of csv=p=0 "$file" 2>/dev/null || echo 0)
        codec=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$file" 2>/dev/null || echo "unknown")
        size=$(du -h "$file" | cut -f1)
        name=$(basename "$file")

        if [ "$res" -ge 2160 ] && [[ "$codec" == "h264" ]]; then
            echo "⚠️ 4K using old H.264 → $name ($size)" | tee -a "'"$REPORT_DIR/low_quality_files.txt"'"
        elif [ "$res" -le 720 ] && [[ "$file" == *"/4K/"* || "$file" == *"/1080p/"* ]]; then
            echo "⚠️ Low resolution in high-res folder → $name (${res}p)" | tee -a "'"$REPORT_DIR/low_quality_files.txt"'"
        fi
    '
    echo "✅ Quality analysis complete."
}

# =============================================================================
# 4. Metadata Report (Light)
# =============================================================================
metadata_report() {
    echo "📋 Jellyfin Metadata Report"
    read -rp "Jellyfin URL (e.g. http://192.168.1.50:8096): " JELLYFIN_URL
    read -rp "API Key: " API_KEY

    JELLYFIN_URL="${JELLYFIN_URL%/}"
    curl -s -H "X-Emby-Token: $API_KEY" "$JELLYFIN_URL/Items?Recursive=true&IncludeItemTypes=Movie,Series&Fields=Path,ProviderIds,Overview,ImageTags" > "$REPORT_DIR/jellyfin_items.json"

    echo "✅ Metadata report saved to $REPORT_DIR"
}

# =============================================================================
# Main Menu
# =============================================================================
if [[ "$MODE" == "menu" || -z "$MODE" ]]; then
    echo ""
    echo "What would you like to do?"
    echo "1) Interactive Duplicate Cleanup"
    echo "2) Scan for Broken Files"
    echo "3) Quality Analyzer"
    echo "4) Metadata Report"
    echo "5) Full Analysis"
    echo "6) Exit"
    read -r choice

    case $choice in
        1) interactive_duplicate_cleanup ;;
        2) scan_broken_files ;;
        3) analyze_quality ;;
        4) metadata_report ;;
        5) scan_broken_files; analyze_quality; interactive_duplicate_cleanup ;;
        *) echo "Goodbye!"; exit 0 ;;
    esac
else
    interactive_duplicate_cleanup
fi

echo ""
echo "✅ All done! Check $REPORT_DIR for reports."
