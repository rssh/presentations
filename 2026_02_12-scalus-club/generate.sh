#!/usr/bin/env bash
# Generate HTML presentation from markdown slides.
# Uses Marp CLI (npx @marp-team/marp-cli) which is already available.
#
# Usage:
#   ./generate.sh          # generate slides.html
#   ./generate.sh --open   # generate and open in browser
#
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT="$DIR/slides.md"
OUTPUT="$DIR/slides.html"

echo "Generating $OUTPUT from $INPUT ..."
npx --yes @marp-team/marp-cli "$INPUT" --html --output "$OUTPUT"
echo "Done: $OUTPUT"

if [[ "${1:-}" == "--open" ]]; then
    open "$OUTPUT"
fi
