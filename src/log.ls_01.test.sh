#!/bin/bash
set -e

# \TEST00 log <path> emits log to path and stream to stdout
LOG=$(mktemp)
STDOUT=$(mktemp)

echo hey there | src/log.ls $LOG > $STDOUT

diff $STDOUT - <<EOF
hey there
EOF


# \TEST01 w/o filename
echo hey there | src/log.ls > $LOG
[ $(cat $LOG | wc -l) = 1 ]
