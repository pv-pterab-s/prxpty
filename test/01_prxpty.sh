#!/bin/bash
set -e

echo [TEST] $0


# \TEST01 exec with no filters
echo "[TEST01]"
TEMP=$(mktemp)
prxpty bash -c 'echo hey' > $TEMP
echo -en 'hey\r\n' | cmp $TEMP -

# \TEST02 exec with one passthru out filter
echo "[TEST02]"
TEMP=$(mktemp)
prxpty -o cat bash -c 'echo hey' > $TEMP
echo -en 'hey\r\n' | cmp $TEMP -

# \TEST03 exec with one passthru in filter
echo "[TEST03]"
TEMP=$(mktemp)
prxpty -i cat bash -c 'echo hey' > $TEMP
echo -en 'hey\r\n' | cmp $TEMP -


# \TEST04 exec thru in and out passthru filter
echo "[TEST04]"
TEMP=$(mktemp)
prxpty -i cat -o cat bash -c 'echo hey' > $TEMP
echo -en 'hey\r\n' | cmp $TEMP -


echo [PASS] $0
