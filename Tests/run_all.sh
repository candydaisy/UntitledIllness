#!/bin/sh
# Runs every Tests/test_*.gd headless. Exits 1 if any test doesn't print PASS.
cd "$(dirname "$0")/.." || exit 1
status=0
for t in Tests/test_*.gd; do
	out=$(timeout 120 godot --headless --path . -s "res://$t" 2>&1 | grep -E "^(PASS|FAIL)")
	echo "$t: ${out:-no result}"
	[ "$out" = "PASS" ] || status=1
done
exit $status
