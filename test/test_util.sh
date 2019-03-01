# -*- compile-command: "cd ../ && ./test/00_test.sh"; -*-
# source for chk utilities (split, here, to be tested)
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
  REGEXP="$REGEXP/[0-9]+_$LEAF\(\.[^.]*\|$\)"
  echo $REGEXP
}

function path_to_test {  # drop src dir, ext off target (\UNTESTED)
  local TARGET="$1"
  SRC=${PRXPTY}src/
  RELPATH=$(echo $TARGET | sed 's@^.*src/@@g')
  echo ${RELPATH%.*}   # drop extension
}
