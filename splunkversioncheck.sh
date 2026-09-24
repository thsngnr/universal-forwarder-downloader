#!/bin/bash
#
# Fetches the current Splunk Enterprise release and all previous releases
# from splunk.com, and keeps version.list (version,build) up to date.
#
# Safe to re-run: existing entries are preserved and de-duplicated, and
# version.list is only replaced once the new data has been validated.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_LIST="$SCRIPT_DIR/version.list"
CURRENT_URL='https://www.splunk.com/en_us/download/splunk-enterprise.html'
PREVIOUS_URL='https://www.splunk.com/en_us/download/previous-releases.html?locale=en_us'

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

fetch() {
    # fetch <url> <output-file>
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --retry 3 -o "$2" "$1"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$2" "$1"
    else
        echo "error: need curl or wget installed" >&2
        return 1
    fi
}

echo
echo "Fetching current release page"
if ! fetch "$CURRENT_URL" "$WORKDIR/splunkDownload.html"; then
    echo "error: could not download $CURRENT_URL, aborting (version.list left untouched)" >&2
    exit 1
fi

current_entry=$(grep -oE 'data-link="https://.*data-md5' "$WORKDIR/splunkDownload.html" \
    | head -1 \
    | grep -oE 'splunk-[^"]*"' \
    | sed -E 's/^splunk-//; s/"$//')
current_version=$(echo "$current_entry" | sed -E 's/-.*//')
current_build=$(echo "$current_entry" | grep -oE '[[:digit:]]-[[:alnum:]]+-' | sed -E 's/^[[:digit:]]-//; s/-$//')

if [[ -z "$current_version" || -z "$current_build" ]]; then
    echo "warning: could not parse current version/build from $CURRENT_URL, skipping that entry" >&2
    current_version=""
    current_build=""
fi

echo
echo "Fetching previous releases page and filling in any gaps"
if ! fetch "$PREVIOUS_URL" "$WORKDIR/olderVersions.html"; then
    echo "error: could not download $PREVIOUS_URL, aborting (version.list left untouched)" >&2
    exit 1
fi

grep -oE 'data-filename="splunk-[^"]*" data-link' "$WORKDIR/olderVersions.html" \
    | sed -E 's/data-filename="splunk-//; s/" data-link//' \
    | grep -E '\.rpm$' \
    | sed -E 's/-linux.*//; s/\.x86.*//; s/-/,/' \
    | sort -u > "$WORKDIR/scraped.list"

{
    [[ -f "$VERSION_LIST" ]] && grep -v '^version,build$' "$VERSION_LIST"
    cat "$WORKDIR/scraped.list"
    [[ -n "$current_version" ]] && echo "$current_version,$current_build"
} | grep -v '^,*$' | sort -t, -k1,1V -u > "$WORKDIR/merged.list"

{
    echo "version,build"
    cat "$WORKDIR/merged.list"
} > "$WORKDIR/new_version.list"

before=$([[ -f "$VERSION_LIST" ]] && grep -c '^' "$VERSION_LIST" || echo 0)
after=$(grep -c '^' "$WORKDIR/new_version.list")

mv "$WORKDIR/new_version.list" "$VERSION_LIST"

echo
echo "Update complete: $VERSION_LIST now has $after lines (was $before)"
echo
