#!/bin/sh
set -eu
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 NEW_OUTPUT_DIRECTORY" >&2
  exit 2
fi
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
"$here/../../scripts/statechart" "$here/RuntimeLookup.tla" \
  --view "$here/view.mjs" --out "$1"
cmp "$here/expected/report.md" "$1/report.md"
cmp "$here/expected/chart.mmd" "$1/chart.mmd"
