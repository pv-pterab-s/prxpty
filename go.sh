#!/bin/bash
# -*- compile-command: "./go.sh"; -*-
set -e



function test_to_tokens {
  echo $1 | sed 's@/@ @g'
}

function test_to_trunk_tokens {
  test_to_tokens $1 | sed 's@[^ ]\+$@@g'
}
function test_to_leaf_token {
  test_to_tokens $1 | sed 's@.* \([^ ]\+\)$@\1@g'
}

function test_to_regexp {
  local REGEXP="^test"
  for TOKEN in $(test_to_trunk_tokens $1) ; do
    REGEXP="$REGEXP/[0-9]+_$TOKEN"
  done
  local LEAF=$(test_to_leaf_token $1)
  REGEXP="$REGEXP/[0-9]+_$LEAF\.[^.]*"
  echo $REGEXP
}


INPUT="pair0/env"
echo $(test_to_trunk_tokens $INPUT) %% $(test_to_leaf_token $INPUT)

INPUT="pair0"
echo $(test_to_trunk_tokens $INPUT) %% $(test_to_leaf_token $INPUT)

INPUT="pair0/next1/env"
echo $(test_to_trunk_tokens $INPUT) %% $(test_to_leaf_token $INPUT)

INPUT="pair0/env"
echo $(test_to_regexp $INPUT)
find test -regex "$(test_to_regexp $INPUT)"

INPUT="pair0"
echo $(test_to_regexp $INPUT)
find test -regex "$(test_to_regexp $INPUT)"

INPUT="pair0/next1/env"
echo $(test_to_regexp $INPUT)
find test -regex "$(test_to_regexp $INPUT)"
