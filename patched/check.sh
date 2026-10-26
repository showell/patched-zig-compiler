#!/bin/sh
# The patches' own checks, against a built compiler: check.sh <zig>
# Each fails on unpatched 0.17.0 and passes with the patches.
set -eu
zig=$1
here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

echo "== $("$zig" version)"

# Zir.getFnPayload: a generic instance's debug rows are at its own lines.
# pick's prologue is line 3, its body line 5, its epilogue line 6; unpatched
# they were 24, 5, 25, past the end of the 11-line file.
"$zig" test "$here/debug_lines.zig" --test-no-exec -femit-bin="$work/bin"
rows=$(readelf --debug-dump=decodedline "$work/bin" 2>/dev/null | awk '$1=="debug_lines.zig" && $2!="-" && $2+0 < 8 {printf "%s ", $2}')
echo "pick's rows: $rows"
[ "$rows" = "3 5 6 " ] || { echo "FAIL: expected pick's rows at 3 5 6"; exit 1; }

# std.heap.ArenaAllocator: a request that does not fit grows the node once.
"$zig" test "$here/arena_growth.zig"

echo "PASS: both patches"
