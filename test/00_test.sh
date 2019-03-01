#!/bin/bash
set -e

. $(dirname $0)/test_util.sh

function exec_test_to_regexp {
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
}

diff <(exec_test_to_regexp) - <<EOF
pair0 %% env
%% pair0
pair0 next1 %% env
^test/[0-9]+_pair0/[0-9]+_env\(\.[^.]*\|$\)
test/02_pair0/00_env.sh
^test/[0-9]+_pair0\(\.[^.]*\|$\)
test/02_pair0
^test/[0-9]+_pair0/[0-9]+_next1/[0-9]+_env\(\.[^.]*\|$\)
EOF
