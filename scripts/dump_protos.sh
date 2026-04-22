#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/proto"
RAW_DIR="$(mktemp -d -t proto-dump.XXXXXX)"
trap 'rm -rf "$RAW_DIR"' EXIT

APPS=(
    "/Applications/Pages Creator Studio.app"
    "/Applications/Numbers Creator Studio.app"
    "/Applications/Keynote Creator Studio.app"
)

for app in "${APPS[@]}"; do
    if [ ! -d "$app" ]; then
        echo "Error: $app not found"
        exit 1
    fi
done

command -v swift >/dev/null 2>&1 || { echo "Error: swift is not installed"; exit 1; }

echo "Building proto-dump..."
cd "$REPO_ROOT"
swift build --product proto-dump

PROTO_DUMP="$REPO_ROOT/.build/debug/proto-dump"

for app in "${APPS[@]}"; do
    echo "Dumping: $app"
    "$PROTO_DUMP" --output "$RAW_DIR" "$app"
done

echo "Deduplicating into: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
"$PROTO_DUMP" --deduplicate "$RAW_DIR" --output "$OUTPUT_DIR"

echo "Done. Protos written to: $OUTPUT_DIR"
