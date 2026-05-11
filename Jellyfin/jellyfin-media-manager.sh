#!/bin/bash
# =============================================================================
# Jellyfin Media Manager v1.7 - Full
# Smart Duplicates + Broken Scanner + Quality + *arr Search Integration
# Author: M-Endymion
# =============================================================================

set -euo pipefail

MEDIA_PATH="${1:-/media}"
MODE="${2:-menu}"

REPORT_DIR="$HOME/jellyfin-reports/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT_DIR"

echo "🚀 Jellyfin Media Manager v1.7"
echo "Media Path: $MEDIA_PATH"
echo "========================================"

# =============================================================================
# *arr Search Integration
# =============================================================================
trigger_arr_search() {
    local title="$1"
    echo -e "\n🎯 Found issue with: $title"
    echo "Would you like to trigger a search?"
    echo "1) Radarr (Movies)"
    echo "2) Sonarr (TV Shows)"
    echo "3) Skip"
    read -r choice

    case $choice in
        1)
            read -rp "Radarr URL (e.g. http://192.168.1.50:7878): " RADARR_URL
            read -rp "Radarr API Key: " RADARR_KEY
            if [[ -n "$RADARR_URL" && -n "$RADARR_KEY" ]]; then
                RADARR_URL="${RADARR_URL%/}"
                echo "Triggering search in Radarr..."
                curl -s -X POST \
                     -H "X-Api-Key: $RADARR_KEY" \
                     -H "Content-Type: application/json" \
                     -d "{\"name\":\"MoviesSearch\",\"movieIds\":[]}" \
                     "$RADARR_URL/api/v3/command" > /dev/null && \
                echo "✅ Search command sent to Radarr"
            fi
            ;;
        2)
            echo "Sonarr search support coming soon."
            ;;
        *) echo "Skipped." ;;
    esac
}

# =============================================================================
# Interactive Duplicate Cleanup
# =============================================================================
interactive_duplicate_cleanup() {
    echo "🔍 Scanning for duplicates..."
    > "$REPORT_DIR/duplicates_to_review.txt"

    find "$MEDIA_PATH" -type f \( -iname "*.mkv" -o -iname "*.mp4" \) | 
    while read -r file; do
        title=$(basename "$file" | sed -E 's/\.(mkv|mp4|avi)$//i' | sed -E 's/\.[0-9]{4}.*//' | sed -E 's/\.(1080p|2160p|720p|4K|WEB|BluRay).*//i' | sed 's/[._]/ /g' | awk '{$1=$1};1')
        echo "$title|$file"
    done | sort | 
    awk -F'|' '{count[$1]++; files[$1]=files[$1] $2 "\n"} END {for (t in count) if (count[t]>1) print count[t] "|" t "|" files[t]}' > "$REPORT_DIR/duplicates_to_review.txt"

    while IFS='|' read -r count title files; do
        [[ -z "$title" ]] && continue
        echo -e "\n🔄 Group: $title ($count versions)"
        echo "$files" | while read -r f; do
            [[ -f "$f" ]] && echo "   $(du -h "$f" | cut -f1) | $(ffprobe -v quiet -select_streams v:0 -show_entries stream=height -of csv=p=0 "$f" 2>/dev/null || echo "?")p → $f"
        done

        echo -e "\nAction?"
        echo "1) Keep best, move rest"
        echo "2) Skip"
        echo "3) Move ALL"
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
        esac
    done < "$REPORT_DIR/duplicates_to_review.txt"
}

# =============================================================================
# Broken File Scanner + *arr Trigger
# =============================================================================
scan_broken_files() {
    echo "🩺 Scanning for broken files..."
    > "$REPORT_DIR/broken_files.txt"

    find "$MEDIA_PATH" -type f \( -iname "*.mkv" -o -iname "*.mp4" \) -print0 | 
    xargs -0 -I {} bash -c '
        file="{}"
        if ! ffprobe -v quiet -print_format json -show_format -show_streams "$file" > /dev/null 2>&1; then
            echo "❌ CORRUPT → $file" | tee -a "'"$REPORT_DIR/broken_files.txt"'"
            title=$(basename "$file" | sed -E "s/\.(mkv|mp4).*//i")
            echo "$title" >> "'"$REPORT_DIR/broken_titles.txt"'"
        fi
    '

    if [[ -s "$REPORT_DIR/broken_titles.txt" ]]; then
        echo -e "\nFound broken files. Trigger *arr searches?"
        read -r -p "(y/n): " trigger
        if [[ "$trigger" == "y" ]]; then
            while IFS= read -r title; do
                trigger_arr_search "$title"
            done < "$REPORT_DIR/broken_titles.txt"
        fi
    fi
}

# =============================================================================
# Quality Analyzer
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
            echo "⚠️ Low resolution in high-res folder → $name" | tee -a "'"$REPORT_DIR/low_quality_files.txt"'"
        fi
    '
}

# =============================================================================
# Main Menu
# =============================================================================
if [[ "$MODE" == "menu" || -z "$MODE" ]]; then
    echo ""
    echo "Select an option:"
    echo "1) Interactive Duplicate Cleanup"
    echo "2) Scan for Broken Files (+ *arr Search)"
    echo "3) Quality Analyzer"
    echo "4) Full Analysis"
    echo "5) Exit"
    read -r choice

    case $choice in
        1) interactive_duplicate_cleanup ;;
        2) scan_broken_files ;;
        3) analyze_quality ;;
        4) scan_broken_files; analyze_quality; interactive_duplicate_cleanup ;;
        *) echo "Goodbye!"; exit 0 ;;
    esac
fi

echo ""
echo "✅ Operation completed! Reports saved to: $REPORT_DIR"
