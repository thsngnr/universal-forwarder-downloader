#!/bin/bash
#
# Universal Forwarder downloader.
#
# Shows an interactive menu (whiptail, falling back to dialog, falling
# back to a plain numbered menu) of the Splunk Universal Forwarder
# versions listed in version.list, then fetches the chosen Linux amd64
# .tgz package directly from download.splunk.com.
#
# Usage:
#   ./uf-downloader.sh                # interactive menu
#   ./uf-downloader.sh 10.4.3         # non-interactive, version given directly
#   ./uf-downloader.sh 10.4.3 /path   # ...and a custom output directory

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_LIST="$SCRIPT_DIR/version.list"
TITLE="Universal Forwarder Downloader"

if [[ ! -f "$VERSION_LIST" ]]; then
    echo "error: $VERSION_LIST not found" >&2
    exit 1
fi

version="${1:-}"
outdir="${2:-.}"

# Versions newest-first, as "version,build" pairs.
versions_newest_first() {
    tail -n +2 "$VERSION_LIST" | sort -t, -k1,1Vr
}

choose_version_menu() {
    local items=() v b
    while IFS=, read -r v b; do
        items+=("$v" "build $b")
    done < <(versions_newest_first)

    if command -v whiptail >/dev/null 2>&1; then
        whiptail --title "$TITLE" \
            --menu "Which Universal Forwarder version would you like to download?" \
            20 60 12 "${items[@]}" \
            3>&1 1>&2 2>&3
        return
    fi

    if command -v dialog >/dev/null 2>&1; then
        dialog --title "$TITLE" \
            --menu "Which Universal Forwarder version would you like to download?" \
            20 60 12 "${items[@]}" \
            3>&1 1>&2 2>&3
        return
    fi

    # Plain fallback: numbered select menu, no whiptail/dialog available.
    echo "$TITLE" >&2
    echo >&2
    local versions=()
    while IFS=, read -r v _; do versions+=("$v"); done < <(versions_newest_first)
    PS3="Which version would you like to download? (enter a number) "
    select v in "${versions[@]}"; do
        [[ -n "$v" ]] && { echo "$v"; return; }
        echo "Invalid choice, try again." >&2
    done
}

if [[ -z "$version" ]]; then
    version="$(choose_version_menu)"
    [[ -z "$version" ]] && { echo "Cancelled." >&2; exit 1; }
fi

build=$(awk -F, -v v="$version" '$1 == v {print $2}' "$VERSION_LIST")

if [[ -z "$build" ]]; then
    echo "error: '$version' is not a listed, available version" >&2
    exit 1
fi

filename="splunkforwarder-${version}-${build}-linux-amd64.tgz"
url="https://download.splunk.com/products/universalforwarder/releases/${version}/linux/${filename}"
mkdir -p "$outdir"
dest="$outdir/$filename"

echo
echo "Downloading: $url"
if ! curl -fSL --retry 3 -o "$dest" "$url"; then
    echo "error: download failed (this package may no longer be on the Splunk site)" >&2
    rm -f "$dest"
    exit 1
fi

size=$(wc -c < "$dest")
if [[ "$size" -eq 0 ]]; then
    echo "error: downloaded file is empty, removing it" >&2
    rm -f "$dest"
    exit 1
fi

echo
echo "Done: $dest ($size bytes)"
echo
