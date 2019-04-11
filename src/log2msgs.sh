#!/bin/bash
set -e

LOGNO=0
sed 's/^.\{12\}//g' $1 | while read LINE ; do
  echo $LOGNO": "$(echo $LINE | base64 --decode)" "
  LOGNO=$((LOGNO + 1))
done


# # utility
# function log2msgs {
#   cat $1 |
# }
# GOLDLOG=$(mktemp)
# echo test message | src/log.ls $GOLDLOG > /dev/null
