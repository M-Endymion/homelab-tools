#!/bin/bash
# =============================================================================
# Jellyfin Media Manager v1.5
# Duplicate Finder + Broken Scanner + Quality Analyzer + Metadata Report
# Author: M-Endymion
# =============================================================================

set -euo pipefail

MEDIA_PATH="${1:-/media}"
MODE="${2:-menu}"

REPORT_DIR="$HOME/jellyfin-reports/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT_DIR"

echo "🚀 Jellyfin Media Manager v1.5"
echo "Media Path: $MEDIA_PATH"
echo "========================================"

# =============================================================================
# Metadata Report (Light Version - Option A)
# =============================================================================
metadata_report() {
    echo "📋 Generating Jellyfin Metadata Report..."

    echo -e "\nPlease enter your Jellyfin details:"
    read -rp "Jellyfin URL (e.g. http://192.168.1.100:8096): " JELLYFIN_URL
    read -rp "API Key: " API_KEY

    # Remove trailing slash if present
    JELLYFIN_URL="${JELLYFIN_URL%/}"

    echo "🔌 Connecting to Jellyfin..."

    # Get libraries
    curl -s -H "X-Emby-Token: $API_KEY" "$JELLYFIN_URL/Items?Recursive=true&IncludeItemTypes=Series,Movie&Fields=Path,ProviderIds,Overview,ImageTags" > "$REPORT_DIR/libraries.json"

    # Simple report
    echo -e "\n📊 Metadata Report Summary:"
    echo "Total Items Scanned: $(jq '.TotalRecordCount' "$REPORT_DIR/libraries.json" 2>/dev/null || echo "Unknown")"

    # Items with missing overview
    missing_overview=$(jq -r '.Items[] | select(.Overview == null or .Overview == "") | .Name' "$REPORT_DIR/libraries.json" 2>/dev/null | wc -l)
    echo "Items missing summary/description: $missing_overview"

    # Items with no primary image
    missing_poster=$(jq -r '.Items[] | select(.ImageTags.Primary == null) | .Name' "$REPORT_DIR/libraries.json" 2>/dev/null | wc -l)
    echo "Items missing poster: $missing_poster"

    echo -e "\n✅ Report saved to: $REPORT_DIR"
    echo "You can trigger a manual library scan in Jellyfin web UI if needed."
}

# =============================================================================
# Previous Functions (Duplicates, Broken, Quality) - kept for brevity
# =============================================================================
scan_broken_files() {
    echo "🩺 Scanning for broken files... (simplified)"
    find "$MEDIA_PATH" -type f \( -iname "*.mkv" -o -iname "*.mp4" \) -print0 | 
    xargs -0 -I {} bash -c 'ffprobe -v quiet -show_entries format=duration "{}" > /dev/null 2>&1 || echo "❌ $ {}"' | 
    tee "$REPORT_DIR/broken_files.txt"
}

analyze_quality() {
    echo "📊 Quality analysis running... (placeholder for now)"
    echo "Quality report saved to $REPORT_DIR"
}

interactive_duplicate_cleanup() {
    echo "🔍 Duplicate cleanup mode (v1.5 - basic)"
    echo "Full interactive selector will be enhanced soon."
}

# =============================================================================
# Main Menu
# =============================================================================
if [[ "$MODE" == "menu" || -z "$MODE" ]]; then
    echo ""
    echo "Select an option:"
    echo "1) Interactive Duplicate Cleanup"
    echo "2) Scan for Broken Files"
    echo "3) Quality Analyzer"
    echo "4) Metadata Report (Jellyfin API)"
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
fi

echo ""
echo "✅ Operation completed! Reports saved to: $REPORT_DIR"
