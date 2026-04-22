#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GENERATED_DIR="$REPO_ROOT/Sources/WorkKit/Generated"

APPS=(
    "Pages:/Applications/Pages Creator Studio.app"
    "Numbers:/Applications/Numbers Creator Studio.app"
    "Keynote:/Applications/Keynote Creator Studio.app"
)

cd "$SCRIPT_DIR"

if [ ! -d .venv ]; then
    echo "Error: .venv not found in $SCRIPT_DIR. Run: uv venv && uv pip install frida-tools"
    exit 1
fi
# shellcheck disable=SC1091
source .venv/bin/activate

echo "==> [1/6] Launching apps for Frida attach"
for entry in "${APPS[@]}"; do
    open -g -a "${entry#*:}"
done
# Give apps a moment to initialize before frida attaches
for _ in $(seq 1 10); do
    READY=1
    for entry in "${APPS[@]}"; do
        pgrep -x "${entry%%:*}" >/dev/null || READY=0
    done
    [ "$READY" = "1" ] && break
    sleep 1
done

echo "==> [2/6] Extracting TSPRegistry from each app"
for entry in "${APPS[@]}"; do
    "$SCRIPT_DIR/extract_registry.sh" "${entry%%:*}"
done

echo "==> [3/6] Merging registries → common_registry.json"
"$SCRIPT_DIR/merge_registry.sh"

echo "==> [4/6] Dumping .proto files from app bundles"
"$SCRIPT_DIR/dump_protos.sh"

echo "==> [5/6] Compiling .proto → .pb.swift"
"$SCRIPT_DIR/generate_pb_swift.sh"

echo "==> [6/6] Scanning extensions + generating decoders"
python generate_ext_map.py "$GENERATED_DIR/Protos"
python generate_types.py
mv CommonDecoder.swift KeynoteDecoder.swift NumbersDecoder.swift PagesDecoder.swift "$GENERATED_DIR/"

echo "Done. Verify with: swift build"
