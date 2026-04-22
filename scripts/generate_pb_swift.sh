#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROTO_DIR="$REPO_ROOT/proto"
OUTPUT_DIR="$REPO_ROOT/Sources/WorkKit/Generated/Protos"

command -v protoc >/dev/null 2>&1 || { echo "Error: protoc is not installed. Run: brew install protobuf"; exit 1; }
command -v protoc-gen-swift >/dev/null 2>&1 || { echo "Error: protoc-gen-swift is not installed. Run: brew install swift-protobuf"; exit 1; }

if [ ! -d "$PROTO_DIR" ]; then
    echo "Error: $PROTO_DIR not found. Run dump_protos.sh first."
    exit 1
fi

echo "Regenerating .pb.swift files into: $OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

cd "$PROTO_DIR"
protoc --proto_path=. --swift_out="$OUTPUT_DIR" -- *.proto

COUNT=$(find "$OUTPUT_DIR" -maxdepth 1 -name '*.pb.swift' | wc -l | tr -d ' ')
echo "Done. Generated $COUNT .pb.swift file(s)."
