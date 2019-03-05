#!/bin/bash
set -e

# evaluate standalone and simple passthru filters
TESTNO=00
function do_test {
  echo "[TEST$(printf '%0.2d' $TESTNO)]"
  local TEMP=$(mktemp)
  $* bash -c "$CMD" > $TEMP
  echo -en "${GOLD}\r\n" | cmp $TEMP -
  TESTNO=$(printf '%0.2d' $((TESTNO + 1)))
}

CMD='echo hey' GOLD='hey' do_test prxpty
CMD='echo hey' GOLD='hey' do_test prxpty -o cat
CMD='echo hey' GOLD='hey' do_test prxpty -i cat
CMD='echo hey' GOLD='hey' do_test prxpty -i cat -o cat
