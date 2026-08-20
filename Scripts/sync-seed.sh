#!/bin/sh
# Refreshes the bundled seed from the data repository. The app ships the
# catalog and badge styles so the whole network is searchable offline; the
# timetables themselves are downloaded.
set -e
DATA="${OVERHEAD_DATA:-$(cd "$(dirname "$0")/../../OverheadData" && pwd)}"
SEED="$(cd "$(dirname "$0")/.." && pwd)/StaticData"

if [ ! -f "$DATA/catalog.json" ]; then
  echo "No data repo at $DATA — set OVERHEAD_DATA" >&2
  exit 1
fi

rm -rf "$SEED/BadgeStyles"
mkdir -p "$SEED"
cp "$DATA/catalog.json" "$SEED/catalog.json"
cp -R "$DATA/BadgeStyles" "$SEED/BadgeStyles"
echo "seed refreshed: catalog + $(ls "$SEED/BadgeStyles" | wc -l | tr -d ' ') styles"
