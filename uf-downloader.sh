#!/bin/bash
#
# Universal Forwarder downloader.
#
# Interactively asks which Splunk Universal Forwarder version to download
# (from the versions listed in version.list) and fetches the Linux
# amd64 .tgz package for it directly from download.splunk.com.
#
# Usage:
#   ./uf-downloader.sh                # interactive prompt
#   ./uf-downloader.sh 10.4.3         # non-interactive, version given directly
#   ./uf-downloader.sh 10.4.3 /path   # ...and a custom output directory

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_LIST="$SCRIPT_DIR/version.list"

if [[ ! -f "$VERSION_LIST" ]]; then
    echo "error: $VERSION_LIST not found" >&2
    exit 1
fi

version="${1:-}"
outdir="${2:-.}"

if [[ -z "$version" ]]; then
    echo "Available Universal Forwarder versions:"
    echo
    tail -n +2 "$VERSION_LIST" | cut -d, -f1 | sort -t. -k1,1V
    echo
    read -rp "Hangi versiyonu indirmek istersiniz? " version
fi

build=$(awk -F, -v v="$version" '$1 == v {print $2}' "$VERSION_LIST")

if [[ -z "$build" ]]; then
    echo "error: '$version' version.list içinde yok / not a listed, available version" >&2
    exit 1
fi

filename="splunkforwarder-${version}-${build}-linux-amd64.tgz"
url="https://download.splunk.com/products/universalforwarder/releases/${version}/linux/${filename}"
mkdir -p "$outdir"
dest="$outdir/$filename"

echo
echo "İndiriliyor: $url"
if ! curl -fSL --retry 3 -o "$dest" "$url"; then
    echo "error: indirme başarısız (Splunk sitesinde bu paket artık olmayabilir)" >&2
    rm -f "$dest"
    exit 1
fi

size=$(wc -c < "$dest")
if [[ "$size" -eq 0 ]]; then
    echo "error: indirilen dosya boş, siliniyor" >&2
    rm -f "$dest"
    exit 1
fi

echo
echo "Tamamlandı: $dest ($size bytes)"
echo
