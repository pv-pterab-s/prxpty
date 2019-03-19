#!/bin/bash
set -e

# \TEST00 w/ filename as option
LOGTMP=$(mktemp)
OUTTMP=$(mktemp)
echo log to $LOGTMP while out to $OUTTMP
for I in {0..2} ; do
  echo $I
  sleep 1s
done | src/log.ls $LOGTMP | tee $OUTTMP

diff $OUTTMP - <<EOF
0
1
2
EOF


# \TEST01 w/o filename
OUTTMP=$(mktemp)
echo log to $OUTTMP
for I in {0..2} ; do
  echo $I
  sleep 1s
done | src/log.ls | tee $OUTTMP

grep -ne '^............MAo=' $OUTTMP | grep -e '^1:'
grep -ne '^............MQo=' $OUTTMP | grep -e '^2:'
grep -ne '^............Mgo=' $OUTTMP | grep -e '^3:'
