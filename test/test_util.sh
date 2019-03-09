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
  local REGEXP
  for TOKEN in $(test_to_trunk_tokens $1) ; do
    REGEXP="$REGEXP/[0-9]+_$TOKEN"
  done
  local LEAF=$(test_to_leaf_token $1)
  if [ -z "$LEAF" ] ; then
    LEAF="[^.]*"
  fi
  REGEXP="$REGEXP/[0-9]+_$LEAF\(\.[^.]*\|$\)"
  echo $REGEXP
}

function src_path_to_rel_path {  # drop src dir, ext off target (\UNTESTED)
  local SRC=${PRXPTY}src/
  echo $1 | sed 's@^.*src/@@g'
}
